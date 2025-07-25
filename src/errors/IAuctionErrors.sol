// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IAuctionErrors {
    error NoAuctionForProvidedDeltaFutureCollateral(
        int256 futureCollateralAssets, int256 futureRewardCollateralAssets, int256 deltaUserCollateralAssets
    );
    error NoAuctionForProvidedDeltaFutureBorrow(
        int256 futureBorrowAssets, int256 futureRewardBorrowAssets, int256 deltaUserBorrowAssets
    );

    error UnexpectedDeltaUserBorrowAssets(int256 deltaUserBorrowAssets, int256 calculatedDeltaUserBorrowAssets);
    error UnexpectedDeltaUserCollateralAssets(
        int256 deltaUserCollateralAssets, int256 calculatedDeltaUserCollateralAssets
    );
}
