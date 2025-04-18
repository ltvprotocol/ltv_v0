// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct TotalAssetsState {
    uint256 realCollateralAssets;
    uint256 realBorrowAssets;
    uint256 futureBorrowAssets;
    uint256 futureCollateralAssets;
    uint256 futureRewardBorrowAssets;
    uint256 futureRewardCollateralAssets;
    uint256 borrowPrice;
    uint256 collateralPrice;
}

struct TotalAssetsData {
    uint256 collateral;
    uint256 borrow;
    uint256 borrowPrice;
}
