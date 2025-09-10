// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct MaxLowLevelRebalanceCollateralStateData {
    uint256 realCollateralAssets;
    uint256 maxTotalAssetsInUnderlying;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    uint256 collateralPrice;
}
