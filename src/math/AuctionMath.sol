// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import '../State.sol';

abstract contract AuctionMath is State {
  using sMulDiv for int256;

    function calculateDeltaFutureBorrowAssetsFromDeltaUserBorrowAssets(int256 deltaUserBorrowAssets) internal view returns(int256) {
      return (deltaUserBorrowAssets * int256(Constants.AMOUNT_OF_STEPS) * futureBorrowAssets) /
            (int256(Constants.AMOUNT_OF_STEPS) * futureBorrowAssets + int256(getAuctionStep()) * futureRewardBorrowAssets);
    }

    function calculateDeltaFutureCollateralAssetsFromDeltaUserCollateralAssets(int256 deltaUserCollateralAssets) internal view returns(int256) {
      return (deltaUserCollateralAssets * int256(Constants.AMOUNT_OF_STEPS) * futureCollateralAssets) /
            (int256(Constants.AMOUNT_OF_STEPS) * futureCollateralAssets + int256(getAuctionStep()) * futureRewardCollateralAssets);
    }

    function calculateDeltaFutureBorrowAssetsFromDeltaFutureCollateralAssets(int256 deltaFutureCollateralAssets) internal view returns(int256) {
      return deltaFutureCollateralAssets.mulDivDown(futureBorrowAssets, futureCollateralAssets);
    }

    function calculateDeltaFutureCollateralAssetsFromDeltaFutureBorrowAssets(int256 deltaFutureBorrowAssets) internal view returns(int256) {
      return deltaFutureBorrowAssets.mulDivDown(futureCollateralAssets, futureBorrowAssets);
    }

    function calculateDeltaUserFutureRewardBorrowAssetsFromDeltaFutureBorrowAssets(int256 deltaFutureBorrowAssets) internal view returns(int256) {
      return futureRewardBorrowAssets.mulDivDown(deltaFutureBorrowAssets, futureBorrowAssets).mulDivDown(int256(getAuctionStep()), int256(Constants.AMOUNT_OF_STEPS));
    }

    function calculateDeltaUserFutureRewardCollateralAssetsFromDeltaFutureCollateralAssets(int256 deltaFutureCollateralAssets) internal view returns(int256) {
      return futureRewardCollateralAssets.mulDivDown(deltaFutureCollateralAssets, futureCollateralAssets).mulDivDown(int256(getAuctionStep()), int256(Constants.AMOUNT_OF_STEPS));
    }

    function calculateDeltaProtocolFutureRewardBorrowAssetsFromDeltaFutureBorrowAssets(int256 deltaFutureBorrowAssets) internal view returns(int256) {
      return futureRewardBorrowAssets.mulDivDown(deltaFutureBorrowAssets, futureBorrowAssets).mulDivDown(int256(Constants.AMOUNT_OF_STEPS - getAuctionStep()), int256(Constants.AMOUNT_OF_STEPS));
    }

    function calculateDeltaProtocolFutureRewardCollateralAssetsFromDeltaFutureCollateralAssets(int256 deltaFutureCollateralAssets) internal view returns(int256) {
      return futureRewardCollateralAssets.mulDivDown(deltaFutureCollateralAssets, futureCollateralAssets).mulDivDown(int256(Constants.AMOUNT_OF_STEPS - getAuctionStep()), int256(Constants.AMOUNT_OF_STEPS));
    }
}