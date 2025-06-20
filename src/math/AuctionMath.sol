// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/MulDiv.sol";
import "../Constants.sol";
import "src/structs/data/AuctionData.sol";
import "src/structs/state_transition/DeltaAuctionState.sol";
import "src/errors/IAuctionErrors.sol";
import "forge-std/console.sol";

// since auction execution doesn't affect totalAssets we have only two conflicts here,
// executor <=> future executor,
// executor <=> fee collector
library AuctionMath {
    using sMulDiv for int256;

    // delta future borrow needs to be rounded down to make auction reward bigger for future executor
    function calculateDeltaFutureBorrowAssetsFromDeltaUserBorrowAssets(
        int256 deltaUserBorrowAssets,
        int256 futureBorrowAssets,
        int256 futureRewardBorrowAssets,
        int256 auctionStep
    ) private pure returns (int256) {
        return (deltaUserBorrowAssets * int256(Constants.AMOUNT_OF_STEPS)).mulDivDown(
            futureBorrowAssets,
            int256(Constants.AMOUNT_OF_STEPS) * futureBorrowAssets + auctionStep * futureRewardBorrowAssets
        );
    }

    // delta future collateral needs to be rounded up to make rewards bigger for future executor
    function calculateDeltaFutureCollateralAssetsFromDeltaUserCollateralAssets(
        int256 deltaUserCollateralAssets,
        int256 futureCollateralAssets,
        int256 futureRewardCollateralAssets,
        int256 auctionStep
    ) private pure returns (int256) {
        return (deltaUserCollateralAssets * int256(Constants.AMOUNT_OF_STEPS)).mulDivUp(
            futureCollateralAssets,
            int256(Constants.AMOUNT_OF_STEPS) * futureCollateralAssets + auctionStep * futureRewardCollateralAssets
        );
    }

    // delta future borrow needs to be rounded up to make auction more profitable for future executor
    function calculateDeltaFutureBorrowAssetsFromDeltaFutureCollateralAssets(
        int256 deltaFutureCollateralAssets,
        int256 futureBorrowAssets,
        int256 futureCollateralAssets
    ) private pure returns (int256) {
        return deltaFutureCollateralAssets.mulDivUp(futureBorrowAssets, futureCollateralAssets);
    }

    // delta future collateral needs to be rounded down to make auction more profitable for future executor
    function calculateDeltaFutureCollateralAssetsFromDeltaFutureBorrowAssets(
        int256 deltaFutureBorrowAssets,
        int256 futureCollateralAssets,
        int256 futureBorrowAssets
    ) private pure returns (int256) {
        return deltaFutureBorrowAssets.mulDivDown(futureCollateralAssets, futureBorrowAssets);
    }

    // needs to be rounded up to make auction more profitable for future executor
    function calculateDeltaFutureRewardBorrowAssetsFromDeltaFutureBorrowAssets(
        int256 deltaFutureBorrowAssets,
        int256 futureBorrowAssets,
        int256 futureRewardBorrowAssets
    ) private pure returns (int256) {
        return futureRewardBorrowAssets.mulDivUp(deltaFutureBorrowAssets, futureBorrowAssets);
    }

    // needs to be rounded down to make auction more profitable for future executor
    function calculateDeltaFutureRewardCollateralAssetsFromDeltaFutureCollateralAssets(
        int256 deltaFutureCollateralAssets,
        int256 futureCollateralAssets,
        int256 futureRewardCollateralAssets
    ) private pure returns (int256) {
        return futureRewardCollateralAssets.mulDivDown(deltaFutureCollateralAssets, futureCollateralAssets);
    }

    // Fee collector and auction executor conflict. Resolve to give more to auction executor
    function calculateDeltaUserFutureRewardBorrowAssetsFromDeltaFutureRewardBorrowAssets(
        int256 deltaFutureRewardBorrowAssets,
        int256 auctionStep
    ) private pure returns (int256) {
        return deltaFutureRewardBorrowAssets.mulDivUp(auctionStep, int256(Constants.AMOUNT_OF_STEPS));
    }

    // Fee collector and auction executor conflict. Resolve to give more to auction executor
    function calculateDeltaUserFutureRewardCollateralAssetsFromDeltaFutureRewardCollateralAssets(
        int256 deltaFutureRewardCollateralAssets,
        int256 auctionStep
    ) private pure returns (int256) {
        return deltaFutureRewardCollateralAssets.mulDivDown(auctionStep, int256(Constants.AMOUNT_OF_STEPS));
    }

    function calculateExecuteAuctionCollateral(int256 deltaUserCollateralAssets, AuctionData memory data)
        internal
        pure
        returns (DeltaAuctionState memory)
    {
        bool hasOppositeSign = data.futureCollateralAssets * deltaUserCollateralAssets < 0;
        bool deltaWithinAuctionSize;
        {
            int256 availableCollateralAssets = data.futureCollateralAssets + data.futureRewardCollateralAssets;
            deltaWithinAuctionSize = (
                availableCollateralAssets > 0 && availableCollateralAssets >= -deltaUserCollateralAssets
            ) || (availableCollateralAssets < 0 && availableCollateralAssets <= -deltaUserCollateralAssets);
        }
        require(
            hasOppositeSign && deltaWithinAuctionSize,
            IAuctionErrors.NoAuctionForProvidedDeltaFutureCollateral(
                data.futureCollateralAssets, data.futureRewardCollateralAssets, deltaUserCollateralAssets
            )
        );

        DeltaAuctionState memory deltaState;
        deltaState.deltaUserCollateralAssets = deltaUserCollateralAssets;
        deltaState.deltaFutureCollateralAssets = calculateDeltaFutureCollateralAssetsFromDeltaUserCollateralAssets(
            deltaState.deltaUserCollateralAssets,
            data.futureCollateralAssets,
            data.futureRewardCollateralAssets,
            data.auctionStep
        );

        deltaState.deltaFutureBorrowAssets = calculateDeltaFutureBorrowAssetsFromDeltaFutureCollateralAssets(
            deltaState.deltaFutureCollateralAssets, data.futureBorrowAssets, data.futureCollateralAssets
        );

        int256 deltaFutureRewardBorrowAssets = calculateDeltaFutureRewardBorrowAssetsFromDeltaFutureBorrowAssets(
            deltaState.deltaFutureBorrowAssets, data.futureBorrowAssets, data.futureRewardBorrowAssets
        );
        int256 deltaFutureRewardCollateralAssets =
            deltaState.deltaUserCollateralAssets - deltaState.deltaFutureCollateralAssets;

        deltaState.deltaUserFutureRewardBorrowAssets =
        calculateDeltaUserFutureRewardBorrowAssetsFromDeltaFutureRewardBorrowAssets(
            deltaFutureRewardBorrowAssets, data.auctionStep
        );
        deltaState.deltaUserFutureRewardCollateralAssets =
            deltaState.deltaUserCollateralAssets - deltaState.deltaFutureCollateralAssets;

        deltaState.deltaUserBorrowAssets =
            deltaState.deltaFutureBorrowAssets + deltaState.deltaUserFutureRewardBorrowAssets;

        deltaState.deltaProtocolFutureRewardBorrowAssets =
            deltaFutureRewardBorrowAssets - deltaState.deltaUserFutureRewardBorrowAssets;
        deltaState.deltaProtocolFutureRewardCollateralAssets =
            deltaFutureRewardCollateralAssets - deltaState.deltaUserFutureRewardCollateralAssets;

        return deltaState;
    }

    function calculateExecuteAuctionBorrow(int256 deltaUserBorrowAssets, AuctionData memory data)
        internal
        pure
        returns (DeltaAuctionState memory)
    {
        bool hasOppositeSign = data.futureBorrowAssets * deltaUserBorrowAssets < 0;
        bool deltaWithinAuctionSize;
        {
            int256 availableBorrowAssets = data.futureBorrowAssets + data.futureRewardBorrowAssets;
            deltaWithinAuctionSize = (availableBorrowAssets > 0 && availableBorrowAssets >= -deltaUserBorrowAssets)
                || (availableBorrowAssets < 0 && availableBorrowAssets <= -deltaUserBorrowAssets);
        }
        console.log("first point");
        require(
            hasOppositeSign && deltaWithinAuctionSize,
            IAuctionErrors.NoAuctionForProvidedDeltaFutureBorrow(
                data.futureBorrowAssets, data.futureRewardBorrowAssets, deltaUserBorrowAssets
            )
        );

        DeltaAuctionState memory deltaState;
        deltaState.deltaUserBorrowAssets = deltaUserBorrowAssets;
        deltaState.deltaFutureBorrowAssets = calculateDeltaFutureBorrowAssetsFromDeltaUserBorrowAssets(
            deltaState.deltaUserBorrowAssets, data.futureBorrowAssets, data.futureRewardBorrowAssets, data.auctionStep
        );
        console.log("second point");
        deltaState.deltaFutureCollateralAssets = calculateDeltaFutureCollateralAssetsFromDeltaFutureBorrowAssets(
            deltaState.deltaFutureBorrowAssets, data.futureCollateralAssets, data.futureBorrowAssets
        );
        console.log("third point");

        int256 deltaFutureRewardBorrowAssets = deltaState.deltaUserBorrowAssets - deltaState.deltaFutureBorrowAssets;
        int256 deltaFutureRewardCollateralAssets =
        calculateDeltaFutureRewardCollateralAssetsFromDeltaFutureCollateralAssets(
            deltaState.deltaFutureCollateralAssets, data.futureCollateralAssets, data.futureRewardCollateralAssets
        );

        deltaState.deltaUserFutureRewardCollateralAssets =
        calculateDeltaUserFutureRewardCollateralAssetsFromDeltaFutureRewardCollateralAssets(
            deltaFutureRewardCollateralAssets, data.auctionStep
        );
        deltaState.deltaUserFutureRewardBorrowAssets =
            deltaState.deltaUserBorrowAssets - deltaState.deltaFutureBorrowAssets;

        deltaState.deltaUserCollateralAssets =
            deltaState.deltaFutureCollateralAssets + deltaState.deltaUserFutureRewardCollateralAssets;

        deltaState.deltaProtocolFutureRewardBorrowAssets =
            deltaFutureRewardBorrowAssets - deltaState.deltaUserFutureRewardBorrowAssets;
        deltaState.deltaProtocolFutureRewardCollateralAssets =
            deltaFutureRewardCollateralAssets - deltaState.deltaUserFutureRewardCollateralAssets;

        return deltaState;
    }
}
