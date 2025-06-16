// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct CommonTotalAssetsState {
    int256 futureBorrowAssets;
    int256 futureCollateralAssets;
    int256 futureRewardBorrowAssets;
    int256 futureRewardCollateralAssets;
    uint256 borrowPrice;
    uint256 collateralPrice;
}
