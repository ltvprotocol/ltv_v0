// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/Base.sol";
import "../../../src/dummy/interfaces/IDummyOracle.sol";
import "./RateMath.sol";

contract DynamicOracle is IDummyOracle, CommonBase {
    // Token addresses
    address private immutable collateralToken;
    address private immutable borrowToken;

    // Initial prices
    uint256 private immutable initialBorrowPrice;
    uint256 private immutable initialCollateralPrice;

    // Rate per block (in 1e18 precision)
    uint256 private immutable ratePerBlock;

    // Deployment block number
    uint256 private immutable deploymentBlock;

    uint256 public constant BLOCKS_PER_DAY = 7200;

    constructor(
        address _collateralToken,
        address _borrowToken,
        uint256 _initialCollateralPrice,
        uint256 _initialBorrowPrice,
        uint256 _ratePerBlock
    ) {
        collateralToken = _collateralToken;
        borrowToken = _borrowToken;
        initialBorrowPrice = _initialBorrowPrice;
        initialCollateralPrice = _initialCollateralPrice;
        ratePerBlock = _ratePerBlock;
        deploymentBlock = block.number;
    }

    function getAssetPrice(address asset) external view returns (uint256) {
        if (asset == borrowToken) {
            return initialBorrowPrice; // Borrow token price remains constant
        } else if (asset == collateralToken) {
            return _calculateCollateralPrice();
        }

        revert("Asset not supported");
    }

    function setAssetPrice(address, uint256) external returns (uint256) {}

    /**
     * @dev Calculate the current collateral price based on block number
     * Price increases by yearlyCollateralIncrease from initialCollateralPrice
     */
    function _calculateCollateralPrice() private view returns (uint256) {
        // need BLOCK_PER_DAY division to ensure that price is updated once in a day. It's needed for proper invariant testing
        // where borrow price can be applied, but collateral still remains the same
        uint256 blocksElapsed = (vm.getBlockNumber() - deploymentBlock) / BLOCKS_PER_DAY * BLOCKS_PER_DAY;
        uint256 priceIncrease = RateMath.calculateRatePerBlock(ratePerBlock, blocksElapsed);

        return initialCollateralPrice * priceIncrease / 1e18;
    }
}
