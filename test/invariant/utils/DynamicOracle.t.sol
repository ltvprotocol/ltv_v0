// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {CommonBase} from "forge-std/Base.sol";
import {IDummyOracle} from "src/dummy/interfaces/IDummyOracle.sol";
import {RateMath} from "test/invariant/utils/RateMath.sol";

/**
 * @title DynamicOracle
 * @dev A mock oracle contract for invariant testing that simulates dynamic price movements
 *
 * This contract implements a price oracle where:
 * - Borrow token price remains constant (stablecoin-like behavior)
 * - Collateral token price increases over time based on a configurable rate
 * - Price updates are discretized to daily intervals for proper invariant testing
 */
contract DynamicOracle is IDummyOracle, CommonBase {
    // Token addresses for the two assets in the LTV system
    address private immutable COLLATERAL_TOKEN;
    address private immutable BORROW_TOKEN;

    // Initial prices set at deployment (in 1e18 precision)
    uint256 private immutable INITIAL_BORROW_PRICE;
    uint256 private immutable INITIAL_COLLATERAL_PRICE;

    // Rate per block for price increase (in 1e18 precision)
    // This represents the daily rate of increase for collateral price
    uint256 private immutable RATE_PER_BLOCK;

    // Block number when the oracle was deployed
    // Used as reference point for calculating elapsed time
    uint256 private immutable DEPLOYMENT_BLOCK;

    // Number of blocks per day (7200 blocks = 12 seconds per block)
    // Used to discretize price updates to daily intervals
    uint256 public constant BLOCKS_PER_DAY = 7200;

    /**
     * @dev Constructor initializes the oracle with token addresses and initial prices
     * @param _collateralToken Address of the collateral token (e.g., ETH)
     * @param _borrowToken Address of the borrow token (e.g., USDC)
     * @param _initialCollateralPrice Initial price of collateral token in 1e18 precision
     * @param _initialBorrowPrice Initial price of borrow token in 1e18 precision
     * @param _ratePerBlock Daily rate of increase for collateral price in 1e18 precision
     */
    constructor(
        address _collateralToken,
        address _borrowToken,
        uint256 _initialCollateralPrice,
        uint256 _initialBorrowPrice,
        uint256 _ratePerBlock
    ) {
        COLLATERAL_TOKEN = _collateralToken;
        BORROW_TOKEN = _borrowToken;
        INITIAL_BORROW_PRICE = _initialBorrowPrice;
        INITIAL_COLLATERAL_PRICE = _initialCollateralPrice;
        RATE_PER_BLOCK = _ratePerBlock;
        DEPLOYMENT_BLOCK = uint56(block.number);
    }

    /**
     * @dev Returns the current price of the specified asset
     * @param asset Address of the asset to get price for
     * @return Current price in 1e18 precision
     */
    function getAssetPrice(address asset) external view returns (uint256) {
        if (asset == BORROW_TOKEN) {
            // Borrow token (stablecoin) maintains constant price
            return INITIAL_BORROW_PRICE;
        } else if (asset == COLLATERAL_TOKEN) {
            // Collateral token price increases over time
            return _calculateCollateralPrice();
        }

        revert("Asset not supported");
    }

    /**
     * @dev Mock function to satisfy IDummyOracle interface
     */
    function setAssetPrice(address, uint256) external returns (uint256) {}

    /**
     * @dev Calculate the current collateral price based on elapsed blocks
     *
     * The price increases exponentially based on the rate per block and elapsed time.
     * The BLOCKS_PER_DAY division ensures price updates happen at daily intervals to
     * simulate the real world scenario.
     *
     * @return Current collateral price in 1e18 precision
     */
    function _calculateCollateralPrice() private view returns (uint256) {
        // Calculate blocks elapsed since deployment, rounded down to nearest day
        // This ensures price only changes once per day, not every block
        uint256 blocksElapsed = (vm.getBlockNumber() - DEPLOYMENT_BLOCK) / BLOCKS_PER_DAY * BLOCKS_PER_DAY;

        // Calculate the cumulative price increase factor using RateMath
        uint256 priceIncrease = RateMath.calculateRatePerBlock(RATE_PER_BLOCK, blocksElapsed);

        // Apply the price increase to the initial price
        return INITIAL_COLLATERAL_PRICE * priceIncrease / 1e18;
    }
}
