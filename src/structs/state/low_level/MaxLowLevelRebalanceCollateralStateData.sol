// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct MaxLowLevelRebalanceCollateralStateData {
    uint256 realCollateralAssets;
    uint256 maxTotalAssetsInUnderlying;
    uint16 targetLTVDividend;
    uint16 targetLTVDivider;
    uint256 collateralPrice;
}
