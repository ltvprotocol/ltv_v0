// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title TotalAssetsCollateralData
 * @notice This struct needed for total assets collateral calculations
 */
struct TotalAssetsCollateralData {
    uint256 totalAssets;
    uint256 collateralPrice;
    uint256 borrowPrice;
    uint8 borrowTokenDecimals;
    uint8 collateralTokenDecimals;
}
