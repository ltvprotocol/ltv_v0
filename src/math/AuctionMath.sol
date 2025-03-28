// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../State.sol';

struct AuctionState {
    int256 futureBorrowAssets;
    int256 futureCollateralAssets;
    int256 futureRewardBorrowAssets;
    int256 futureRewardCollateralAssets;
    int256 auctionStep;
}

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

// since auction execution doesn't affect totalAssets we have only one conflict here,
// between executor and future executor
library AuctionMath {
    error NoAuctionForProvidedDeltaFutureCollateral(
        int256 futureCollateralAssets,
        int256 futureRewardCollateralAssets,
        int256 deltaUserCollateralAssets
    );
    error NoAuctionForProvidedDeltaFutureBorrow(int256 futureBorrowAssets, int256 futureRewardBorrowAssets, int256 deltaUserBorrowAssets);
    using sMulDiv for int256;

    // delta future borrow needs to be rounded down to make auction more profitable for future executor
    function calculateDeltaFutureBorrowAssetsFromDeltaUserBorrowAssets(
        int256 deltaUserBorrowAssets,
        AuctionState memory auctionState
    ) private pure returns (int256) {
        return
            (deltaUserBorrowAssets * int256(Constants.AMOUNT_OF_STEPS) * auctionState.futureBorrowAssets) /
            (int256(Constants.AMOUNT_OF_STEPS) * auctionState.futureBorrowAssets + auctionState.auctionStep * auctionState.futureRewardBorrowAssets);
    }

    // delta future collateral needs to be rounded up to make auction more profitable for future executor
    function calculateDeltaFutureCollateralAssetsFromDeltaUserCollateralAssets(
        int256 deltaUserCollateralAssets,
        AuctionState memory auctionState
    ) private pure returns (int256) {
        return
            (deltaUserCollateralAssets * int256(Constants.AMOUNT_OF_STEPS)).mulDivUp(
                auctionState.futureCollateralAssets,
                int256(Constants.AMOUNT_OF_STEPS) *
                    auctionState.futureCollateralAssets +
                    auctionState.auctionStep *
                    auctionState.futureRewardCollateralAssets
            );
    }

    // delta future borrow needs to be rounded down to make auction more profitable for future executor
    function calculateDeltaFutureBorrowAssetsFromDeltaFutureCollateralAssets(
        int256 deltaFutureCollateralAssets,
        AuctionState memory auctionState
    ) private pure returns (int256) {
        return deltaFutureCollateralAssets.mulDivDown(auctionState.futureBorrowAssets, auctionState.futureCollateralAssets);
    }

    // delta future collateral needs to be rounded up to make auction more profitable for future executor
    function calculateDeltaFutureCollateralAssetsFromDeltaFutureBorrowAssets(
        int256 deltaFutureBorrowAssets,
        AuctionState memory auctionState
    ) private pure returns (int256) {
        return deltaFutureBorrowAssets.mulDivUp(auctionState.futureCollateralAssets, auctionState.futureBorrowAssets);
    }

    // needs to be rounded down to make auction more profitable for future executor
    function calculateDeltaFutureRewardBorrowAssetsFromDeltaFutureBorrowAssets(
        int256 deltaFutureBorrowAssets,
        AuctionState memory auctionState
    ) private pure returns (int256) {
        return auctionState.futureRewardBorrowAssets.mulDivDown(deltaFutureBorrowAssets, auctionState.futureBorrowAssets);
    }
    
    // needs to be rounded up to make auction more profitable for future executor
    function calculateDeltaFutureRewardCollateralAssetsFromDeltaFutureCollateralAssets(
        int256 deltaFutureCollateralAssets,
        AuctionState memory auctionState
    ) private pure returns (int256) {
        return auctionState.futureRewardCollateralAssets.mulDivUp(deltaFutureCollateralAssets, auctionState.futureCollateralAssets);
    }

    // Fee collector and auction executor conflict. Resolve to give more to auction executor
    function calculateDeltaUserFutureRewardBorrowAssetsFromDeltaFutureRewardBorrowAssets(
        int256 deltaFutureRewardBorrowAssets,
        AuctionState memory auctionState
    ) private pure returns (int256) {
        return deltaFutureRewardBorrowAssets.mulDivUp(auctionState.auctionStep, int256(Constants.AMOUNT_OF_STEPS));
    }

    // Fee collector and auction executor conflict. Resolve to give more to auction executor
    function calculateDeltaUserFutureRewardCollateralAssetsFromDeltaFutureRewardCollateralAssets(
        int256 deltaFutureRewardCollateralAssets,
        AuctionState memory auctionState
    ) private pure returns (int256) {
        return deltaFutureRewardCollateralAssets.mulDivDown(auctionState.auctionStep, int256(Constants.AMOUNT_OF_STEPS));
    }

    function calculateExecuteAuctionCollateral(
        int256 deltaUserCollateralAssets,
        AuctionState memory auctionState
    ) external pure returns (DeltaAuctionState memory) {
        bool hasOppositeSign = auctionState.futureCollateralAssets * deltaUserCollateralAssets < 0;
        bool deltaWithinAuctionSize = (auctionState.futureCollateralAssets + auctionState.futureRewardCollateralAssets + deltaUserCollateralAssets) *
            (auctionState.futureCollateralAssets + auctionState.futureRewardCollateralAssets) >=
            0;
        require(
            hasOppositeSign && deltaWithinAuctionSize,
            NoAuctionForProvidedDeltaFutureCollateral(
                auctionState.futureCollateralAssets,
                auctionState.futureRewardCollateralAssets,
                deltaUserCollateralAssets
            )
        );

        DeltaAuctionState memory deltaState;
        deltaState.deltaUserCollateralAssets = deltaUserCollateralAssets;
        deltaState.deltaFutureCollateralAssets = calculateDeltaFutureCollateralAssetsFromDeltaUserCollateralAssets(
            deltaState.deltaUserCollateralAssets,
            auctionState
        );

        deltaState.deltaFutureBorrowAssets = calculateDeltaFutureBorrowAssetsFromDeltaFutureCollateralAssets(
            deltaState.deltaFutureCollateralAssets,
            auctionState
        );

        int256 deltaFutureRewardBorrowAssets = calculateDeltaFutureRewardBorrowAssetsFromDeltaFutureBorrowAssets(
            deltaState.deltaFutureBorrowAssets,
            auctionState
        );
        int256 deltaFutureRewardCollateralAssets = calculateDeltaFutureRewardCollateralAssetsFromDeltaFutureCollateralAssets(
            deltaState.deltaFutureCollateralAssets,
            auctionState
        );

        deltaState.deltaUserFutureRewardBorrowAssets = calculateDeltaUserFutureRewardBorrowAssetsFromDeltaFutureRewardBorrowAssets(
            deltaFutureRewardBorrowAssets,
            auctionState
        );
        deltaState.deltaUserFutureRewardCollateralAssets = deltaState.deltaUserCollateralAssets - deltaState.deltaFutureCollateralAssets;

        deltaState.deltaUserBorrowAssets = deltaState.deltaFutureBorrowAssets + deltaState.deltaUserFutureRewardBorrowAssets;

        deltaState.deltaProtocolFutureRewardBorrowAssets = deltaFutureRewardBorrowAssets - deltaState.deltaUserFutureRewardBorrowAssets;
        deltaState.deltaProtocolFutureRewardCollateralAssets = deltaFutureRewardCollateralAssets - deltaState.deltaUserFutureRewardCollateralAssets;

        return deltaState;
    }

    function calculateExecuteAuctionBorrow(
        int256 deltaUserBorrowAssets,
        AuctionState memory auctionState
    ) external pure returns (DeltaAuctionState memory) {
        bool hasOppositeSign = auctionState.futureBorrowAssets * deltaUserBorrowAssets < 0;
        bool deltaWithinAuctionSize = (auctionState.futureBorrowAssets + auctionState.futureRewardBorrowAssets + deltaUserBorrowAssets) *
            (auctionState.futureBorrowAssets + auctionState.futureRewardBorrowAssets) >=
            0;
        require(
            hasOppositeSign && deltaWithinAuctionSize,
            NoAuctionForProvidedDeltaFutureBorrow(auctionState.futureBorrowAssets, auctionState.futureRewardBorrowAssets, deltaUserBorrowAssets)
        );

        DeltaAuctionState memory deltaState;
        deltaState.deltaUserBorrowAssets = deltaUserBorrowAssets;
        deltaState.deltaFutureBorrowAssets = calculateDeltaFutureBorrowAssetsFromDeltaUserBorrowAssets(
            deltaState.deltaUserBorrowAssets,
            auctionState
        );

        deltaState.deltaFutureCollateralAssets = calculateDeltaFutureCollateralAssetsFromDeltaFutureBorrowAssets(
            deltaState.deltaFutureBorrowAssets,
            auctionState
        );

        int256 deltaFutureRewardBorrowAssets = calculateDeltaFutureRewardBorrowAssetsFromDeltaFutureBorrowAssets(
            deltaState.deltaFutureBorrowAssets,
            auctionState
        );
        int256 deltaFutureRewardCollateralAssets = calculateDeltaFutureRewardCollateralAssetsFromDeltaFutureCollateralAssets(
            deltaState.deltaFutureCollateralAssets,
            auctionState
        );

        deltaState.deltaUserFutureRewardCollateralAssets = calculateDeltaUserFutureRewardCollateralAssetsFromDeltaFutureRewardCollateralAssets(
            deltaFutureRewardCollateralAssets,
            auctionState
        );
        deltaState.deltaUserFutureRewardBorrowAssets = deltaState.deltaUserBorrowAssets - deltaState.deltaFutureBorrowAssets;

        deltaState.deltaUserCollateralAssets = deltaState.deltaFutureCollateralAssets + deltaState.deltaUserFutureRewardCollateralAssets;

        deltaState.deltaProtocolFutureRewardBorrowAssets = deltaFutureRewardBorrowAssets - deltaState.deltaUserFutureRewardBorrowAssets;
        deltaState.deltaProtocolFutureRewardCollateralAssets = deltaFutureRewardCollateralAssets - deltaState.deltaUserFutureRewardCollateralAssets;

        return deltaState;
    }
}
