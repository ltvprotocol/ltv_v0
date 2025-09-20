// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title CommonTotalAssetsState
 * @notice This struct needed to represent common assets state
 * which doesn't depend from either operation is deposit or withdraw
 */
struct CommonTotalAssetsState {
    int256 futureBorrowAssets;
    int256 futureCollateralAssets;
    int256 futureRewardBorrowAssets;
    int256 futureRewardCollateralAssets;
    uint256 borrowPrice;
    uint256 collateralPrice;
    uint8 borrowTokenDecimals;
    uint8 collateralTokenDecimals;
}
