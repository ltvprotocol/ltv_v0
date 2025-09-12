// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title MaxLowLevelRebalanceBorrowStateData
 * @notice This struct needed for max low level rebalance borrow calculations
 */
struct MaxLowLevelRebalanceBorrowStateData {
    uint256 realBorrowAssets;
    uint256 maxTotalAssetsInUnderlying;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    uint256 borrowPrice;
    uint256 borrowTokenDecimals;
}
