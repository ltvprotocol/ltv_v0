// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title MaxLowLevelRebalanceSharesData
 * @notice This struct needed for max low level rebalance shares calculations
 */
struct MaxLowLevelRebalanceSharesData {
    uint256 depositRealCollateral;
    uint256 depositRealBorrow;
    uint256 maxTotalAssetsInUnderlying;
    uint256 supplyAfterFee;
    uint256 borrowPrice;
    uint256 depositTotalAssets;
}
