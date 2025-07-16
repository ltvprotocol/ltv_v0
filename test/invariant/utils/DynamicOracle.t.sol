// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/Base.sol";
import "../../../src/dummy/interfaces/IDummyOracle.sol";

contract DynamicOracle is IDummyOracle, CommonBase {
    // Token addresses
    address private immutable collateralToken;
    address private immutable borrowToken;

    // Initial prices
    uint256 private immutable initialBorrowPrice;
    uint256 private immutable initialCollateralPrice;

    // Yearly collateral token price increase (in 1e18 precision)
    uint256 private immutable yearlyCollateralIncrease;

    // Assuming 12 second block time (2,628,000 blocks per year)
    uint256 private constant BLOCKS_PER_YEAR = 2628000;

    // Deployment block number
    uint256 private immutable deploymentBlock;

    constructor(
        address _collateralToken,
        address _borrowToken,
        uint256 _initialCollateralPrice,
        uint256 _initialBorrowPrice,
        uint256 _yearlyCollateralIncrease
    ) {
        collateralToken = _collateralToken;
        borrowToken = _borrowToken;
        initialBorrowPrice = _initialBorrowPrice;
        initialCollateralPrice = _initialCollateralPrice;
        yearlyCollateralIncrease = _yearlyCollateralIncrease;
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
        uint256 blocksElapsed = vm.getBlockNumber() - deploymentBlock;

        uint256 yearsElapsed = blocksElapsed * 1e18 / BLOCKS_PER_YEAR;

        uint256 compoundRate = _calculateCompoundRate(yearsElapsed);

        return (initialCollateralPrice * compoundRate) / 1e18;
    }

    /**
     * @dev Calculate compound rate using the yearly increase rate
     * @param yearsElapsed Years elapsed in 1e18 precision
     * @return Compound rate in 1e18 precision
     */
    function _calculateCompoundRate(uint256 yearsElapsed) private view returns (uint256) {
        if (yearsElapsed == 0) {
            return 1e18; // No increase
        }

        uint256 rate = 1e18 + yearlyCollateralIncrease; // Convert to rate format

        uint256 totalIncrease = ((rate - 1e18) * yearsElapsed) / 1e18;

        return 1e18 + totalIncrease;
    }
}
