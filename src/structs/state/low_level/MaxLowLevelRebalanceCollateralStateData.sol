// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title MaxLowLevelRebalanceCollateralStateData
 * @notice This struct needed for max low level rebalance collateral calculations
 */
struct MaxLowLevelRebalanceCollateralStateData {
    uint256 realCollateralAssets;
    uint256 maxTotalAssetsInUnderlying;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    uint256 collateralPrice;
}
