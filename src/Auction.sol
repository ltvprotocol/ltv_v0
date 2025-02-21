// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import './math/AuctionMath.sol';
import './Lending.sol';

// @todo: consider renaming User -> Real 
struct DeltaAuctionState {
    int256 deltaFutureBorrowAssets;
    int256 deltaFutureCollateralAssets;
    int256 deltaUserCollateralAssets;
    int256 deltaUserBorrowAssets;
    int256 deltaUserFutureRewardCollateralAssets;
    int256 deltaUserFutureRewardBorrowAssets;
    int256 deltaProtocolFutureRewardCollateralAssets;
    int256 deltaProtocolFutureRewardBorrowAssets;
}

event AuctionExecuted(address executor, int256 deltaRealCollateralAssets, int256 deltaRealBorrowAssets);

abstract contract Auction is AuctionMath, Lending {
    error NoAuctionForProvidedDeltaFutureCollateral(int256 futureCollateralAssets, int256 futureRewardCollateralAssets, int256 deltaUserCollateralAssets);
    error NoAuctionForProvidedDeltaFutureBorrow(int256 futureBorrowAssets, int256 futureRewardBorrowAssets, int256 deltaUserBorrowAssets);

    function executeAuctionCollateral(int256 deltaUserCollateralAssets) external returns (int256) {
        DeltaAuctionState memory deltaState = calculateExecuteAuctionCollateral(deltaUserCollateralAssets);

        applyDeltaState(deltaState);
        return deltaState.deltaUserBorrowAssets;
    }

    function executeAuctionBorrow(int256 deltaUserBorrowAssets) external returns (int256) {
        DeltaAuctionState memory deltaState = calculateExecuteAuctionBorrow(deltaUserBorrowAssets);

        applyDeltaState(deltaState);
        return deltaState.deltaUserCollateralAssets;
    }

    function previewExecuteAuctionCollateral(int256 deltaUserCollateralAssets) external view returns (int256) {
        DeltaAuctionState memory deltaState = calculateExecuteAuctionCollateral(deltaUserCollateralAssets);
        return deltaState.deltaUserBorrowAssets;
    }

    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets) external view returns (int256) {
        DeltaAuctionState memory deltaState = calculateExecuteAuctionBorrow(deltaUserBorrowAssets);
        return deltaState.deltaUserCollateralAssets;
    }

    function calculateExecuteAuctionCollateral(int256 deltaUserCollateralAssets) internal view returns (DeltaAuctionState memory) {
        bool hasOppositeSign = futureCollateralAssets * deltaUserCollateralAssets < 0;
        bool deltaWithinAuctionSize = (futureCollateralAssets + futureRewardCollateralAssets + deltaUserCollateralAssets) * (futureCollateralAssets + futureRewardCollateralAssets) >= 0;
        require(hasOppositeSign && deltaWithinAuctionSize, NoAuctionForProvidedDeltaFutureCollateral(futureCollateralAssets, futureRewardCollateralAssets, deltaUserCollateralAssets));

        DeltaAuctionState memory deltaState;
        deltaState.deltaUserCollateralAssets = deltaUserCollateralAssets;
        deltaState.deltaFutureCollateralAssets = calculateDeltaFutureCollateralAssetsFromDeltaUserCollateralAssets(deltaState.deltaUserCollateralAssets);

        deltaState.deltaFutureBorrowAssets = calculateDeltaFutureBorrowAssetsFromDeltaFutureCollateralAssets(deltaState.deltaFutureCollateralAssets);

        int256 deltaFutureRewardBorrowAssets = calculateDeltaFutureRewardBorrowAssetsFromDeltaFutureBorrowAssets(deltaState.deltaFutureBorrowAssets);
        int256 deltaFutureRewardCollateralAssets = calculateDeltaFutureRewardCollateralAssetsFromDeltaFutureCollateralAssets(deltaState.deltaFutureCollateralAssets);

        deltaState.deltaUserFutureRewardBorrowAssets = calculateDeltaUserFutureRewardBorrowAssetsFromDeltaFutureRewardBorrowAssets(deltaFutureRewardBorrowAssets);
        deltaState.deltaUserFutureRewardCollateralAssets = deltaState.deltaUserCollateralAssets - deltaState.deltaFutureCollateralAssets;

        deltaState.deltaUserBorrowAssets = deltaState.deltaFutureBorrowAssets + deltaState.deltaUserFutureRewardBorrowAssets;

        deltaState.deltaProtocolFutureRewardBorrowAssets = deltaFutureRewardBorrowAssets - deltaState.deltaUserFutureRewardBorrowAssets;
        deltaState.deltaProtocolFutureRewardCollateralAssets = deltaFutureRewardCollateralAssets - deltaState.deltaUserFutureRewardCollateralAssets;

        return deltaState;
    }

    function calculateExecuteAuctionBorrow(int256 deltaUserBorrowAssets) internal view returns (DeltaAuctionState memory) {
      bool hasOppositeSign = futureBorrowAssets * deltaUserBorrowAssets < 0;
      bool deltaWithinAuctionSize = (futureBorrowAssets + futureRewardBorrowAssets + deltaUserBorrowAssets) * (futureBorrowAssets + futureRewardBorrowAssets) >= 0;
      require(hasOppositeSign && deltaWithinAuctionSize, NoAuctionForProvidedDeltaFutureBorrow(futureBorrowAssets, futureRewardBorrowAssets, deltaUserBorrowAssets));

      DeltaAuctionState memory deltaState;
      deltaState.deltaUserBorrowAssets = deltaUserBorrowAssets;
      deltaState.deltaFutureBorrowAssets = calculateDeltaFutureBorrowAssetsFromDeltaUserBorrowAssets(deltaState.deltaUserBorrowAssets);

      deltaState.deltaFutureCollateralAssets = calculateDeltaFutureCollateralAssetsFromDeltaFutureBorrowAssets(deltaState.deltaFutureBorrowAssets);

      
      int256 deltaFutureRewardBorrowAssets = calculateDeltaFutureRewardBorrowAssetsFromDeltaFutureBorrowAssets(deltaState.deltaFutureBorrowAssets);
      int256 deltaFutureRewardCollateralAssets = calculateDeltaFutureRewardCollateralAssetsFromDeltaFutureCollateralAssets(deltaState.deltaFutureCollateralAssets);

      deltaState.deltaUserFutureRewardCollateralAssets = calculateDeltaUserFutureRewardCollateralAssetsFromDeltaFutureRewardCollateralAssets(deltaFutureRewardCollateralAssets);
      deltaState.deltaUserFutureRewardBorrowAssets = deltaState.deltaUserBorrowAssets - deltaState.deltaFutureBorrowAssets;

      deltaState.deltaUserCollateralAssets = deltaState.deltaFutureCollateralAssets + deltaState.deltaUserFutureRewardCollateralAssets;

      deltaState.deltaProtocolFutureRewardBorrowAssets = deltaFutureRewardBorrowAssets - deltaState.deltaUserFutureRewardBorrowAssets;
      deltaState.deltaProtocolFutureRewardCollateralAssets = deltaFutureRewardCollateralAssets - deltaState.deltaUserFutureRewardCollateralAssets;

      return deltaState;
    }

    function applyDeltaState(DeltaAuctionState memory deltaState) internal {
        futureBorrowAssets += deltaState.deltaFutureBorrowAssets;
        futureCollateralAssets += deltaState.deltaFutureCollateralAssets;
        futureRewardBorrowAssets += deltaState.deltaProtocolFutureRewardBorrowAssets + deltaState.deltaUserFutureRewardBorrowAssets;
        futureRewardCollateralAssets += deltaState.deltaProtocolFutureRewardCollateralAssets + deltaState.deltaUserFutureRewardCollateralAssets;

        if (deltaState.deltaUserBorrowAssets < 0) {
            collateralToken.transferFrom(msg.sender, address(this), uint256(-deltaState.deltaUserCollateralAssets));
            supply(uint256(-(deltaState.deltaUserCollateralAssets + deltaState.deltaProtocolFutureRewardCollateralAssets)));
            borrow(uint256(-deltaState.deltaUserBorrowAssets));
            borrowToken.transfer(msg.sender, uint256(-deltaState.deltaUserBorrowAssets));
            if (deltaState.deltaProtocolFutureRewardCollateralAssets != 0) {
                collateralToken.transfer(FEE_COLLECTOR, uint256(deltaState.deltaProtocolFutureRewardCollateralAssets));
            }
        } else if (deltaState.deltaUserBorrowAssets > 0) {
            borrowToken.transferFrom(msg.sender, address(this), uint256(deltaState.deltaUserBorrowAssets));
            repay(uint256(deltaState.deltaUserBorrowAssets + deltaState.deltaProtocolFutureRewardBorrowAssets));
            withdraw(uint256(deltaState.deltaUserCollateralAssets));
            collateralToken.transfer(msg.sender, uint256(deltaState.deltaUserCollateralAssets));
            if (deltaState.deltaProtocolFutureRewardBorrowAssets != 0) {
              borrowToken.transfer(FEE_COLLECTOR, uint256(-deltaState.deltaProtocolFutureRewardBorrowAssets));
            }
        }

        emit AuctionExecuted(msg.sender, deltaState.deltaFutureCollateralAssets, deltaState.deltaFutureBorrowAssets);
    }
}