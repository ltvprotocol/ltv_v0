// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './math/AuctionMath.sol';
import './Lending.sol';
import './State.sol';

// @todo: consider renaming User -> Real 

event AuctionExecuted(address executor, int256 deltaRealCollateralAssets, int256 deltaRealBorrowAssets);

abstract contract Auction is State, Lending {
    function executeAuctionCollateral(int256 deltaUserCollateralAssets) external nonReentrant returns (int256) {
        DeltaAuctionState memory deltaState = AuctionMath.calculateExecuteAuctionCollateral(deltaUserCollateralAssets, getAuctionState());

        applyDeltaState(deltaState);
        return deltaState.deltaUserBorrowAssets;
    }

    function executeAuctionBorrow(int256 deltaUserBorrowAssets) external nonReentrant returns (int256) {
        DeltaAuctionState memory deltaState = AuctionMath.calculateExecuteAuctionBorrow(deltaUserBorrowAssets, getAuctionState());

        applyDeltaState(deltaState);
        return deltaState.deltaUserCollateralAssets;
    }

    function previewExecuteAuctionCollateral(int256 deltaUserCollateralAssets) external view returns (int256) {
        DeltaAuctionState memory deltaState = AuctionMath.calculateExecuteAuctionCollateral(deltaUserCollateralAssets, getAuctionState());
        return deltaState.deltaUserBorrowAssets;
    }

    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets) external view returns (int256) {
        DeltaAuctionState memory deltaState = AuctionMath.calculateExecuteAuctionBorrow(deltaUserBorrowAssets, getAuctionState());
        return deltaState.deltaUserCollateralAssets;
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
                collateralToken.transfer(feeCollector, uint256(deltaState.deltaProtocolFutureRewardCollateralAssets));
            }
        } else if (deltaState.deltaUserBorrowAssets > 0) {
            borrowToken.transferFrom(msg.sender, address(this), uint256(deltaState.deltaUserBorrowAssets));
            repay(uint256(deltaState.deltaUserBorrowAssets + deltaState.deltaProtocolFutureRewardBorrowAssets));
            withdraw(uint256(deltaState.deltaUserCollateralAssets));
            collateralToken.transfer(msg.sender, uint256(deltaState.deltaUserCollateralAssets));
            if (deltaState.deltaProtocolFutureRewardBorrowAssets != 0) {
              borrowToken.transfer(feeCollector, uint256(-deltaState.deltaProtocolFutureRewardBorrowAssets));
            }
        }

        emit AuctionExecuted(msg.sender, deltaState.deltaFutureCollateralAssets, deltaState.deltaFutureBorrowAssets);
    }

    function getAuctionState() private view returns (AuctionState memory) {
        return AuctionState({
            futureCollateralAssets: futureCollateralAssets,
            futureBorrowAssets: futureBorrowAssets,
            futureRewardCollateralAssets: futureRewardCollateralAssets,
            futureRewardBorrowAssets: futureRewardBorrowAssets,
            auctionStep: int256(getAuctionStep())
        });
    }
}