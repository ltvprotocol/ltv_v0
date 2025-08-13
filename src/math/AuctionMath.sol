// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/MulDiv.sol";
import "../Constants.sol";
import "src/structs/data/AuctionData.sol";
import "src/structs/state_transition/DeltaAuctionState.sol";
import "src/errors/IAuctionErrors.sol";

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
        uint24 auctionStep,
        uint24 auctionDuration
    ) private pure returns (int256) {
        int256 divider = futureBorrowAssets
            + futureRewardBorrowAssets.mulDivUp(int256(uint256(auctionStep)), int256(uint256(auctionDuration)));

        if (divider == 0) {
            return -futureBorrowAssets;
        }
        return (deltaUserBorrowAssets).mulDivDown(futureBorrowAssets, divider);
    }

    // delta future collateral needs to be rounded up to make rewards bigger for future executor
    function calculateDeltaFutureCollateralAssetsFromDeltaUserCollateralAssets(
        int256 deltaUserCollateralAssets,
        int256 futureCollateralAssets,
        int256 futureRewardCollateralAssets,
        uint24 auctionStep,
        uint24 auctionDuration
    ) private pure returns (int256) {
        int256 divider = futureCollateralAssets
            + futureRewardCollateralAssets.mulDivDown(int256(uint256(auctionStep)), int256(uint256(auctionDuration)));

        if (divider == 0) {
            return -futureCollateralAssets;
        }
        return (deltaUserCollateralAssets).mulDivUp(futureCollateralAssets, divider);
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
        uint24 auctionStep,
        uint24 auctionDuration
    ) private pure returns (int256) {
        return deltaFutureRewardBorrowAssets.mulDivDown(int256(uint256(auctionStep)), int256(uint256(auctionDuration)));
    }

    // Fee collector and auction executor conflict. Resolve to give more to auction executor
    function calculateDeltaUserFutureRewardCollateralAssetsFromDeltaFutureRewardCollateralAssets(
        int256 deltaFutureRewardCollateralAssets,
        uint24 auctionStep,
        uint24 auctionDuration
    ) private pure returns (int256) {
        return
            deltaFutureRewardCollateralAssets.mulDivUp(int256(uint256(auctionStep)), int256(uint256(auctionDuration)));
    }

    function availableDeltaUserBorrowAssets(
        int256 futureRewardBorrowAssets,
        uint24 auctionStep,
        uint24 auctionDuration,
        int256 futureBorrowAssets
    ) internal pure returns (int256) {
        int256 deltaUserRewardBorrowAssets = calculateDeltaUserFutureRewardBorrowAssetsFromDeltaFutureRewardBorrowAssets(
            -futureRewardBorrowAssets, auctionStep, auctionDuration
        );
        return futureBorrowAssets - deltaUserRewardBorrowAssets;
    }

    function availableDeltaUserCollateralAssets(
        int256 futureRewardCollateralAssets,
        uint24 auctionStep,
        uint24 auctionDuration,
        int256 futureCollateralAssets
    ) internal pure returns (int256) {
        int256 userRewardCollateralAssets =
        calculateDeltaUserFutureRewardCollateralAssetsFromDeltaFutureRewardCollateralAssets(
            -futureRewardCollateralAssets, auctionStep, auctionDuration
        );

        return futureCollateralAssets - userRewardCollateralAssets;
    }

    function calculateExecuteAuctionCollateral(int256 deltaUserCollateralAssets, AuctionData memory data)
        internal
        pure
        returns (DeltaAuctionState memory)
    {
        bool hasOppositeSign = data.futureCollateralAssets * deltaUserCollateralAssets < 0;
        bool deltaWithinAuctionSize;
        {
            int256 availableCollateralAssets = availableDeltaUserCollateralAssets(
                data.futureRewardCollateralAssets, data.auctionStep, data.auctionDuration, data.futureCollateralAssets
            );
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

        // in case of negative auction rewards are in borrow
        if (deltaUserCollateralAssets > 0) {
            deltaState.deltaFutureCollateralAssets = deltaUserCollateralAssets;
            deltaState.deltaFutureBorrowAssets = calculateDeltaFutureBorrowAssetsFromDeltaFutureCollateralAssets(
                deltaState.deltaFutureCollateralAssets, data.futureBorrowAssets, data.futureCollateralAssets
            );

            if (deltaState.deltaFutureBorrowAssets == -data.futureBorrowAssets) {
                deltaState.deltaFutureCollateralAssets = -data.futureCollateralAssets;
            }

            int256 deltaFutureRewardBorrowAssets = calculateDeltaFutureRewardBorrowAssetsFromDeltaFutureBorrowAssets(
                deltaState.deltaFutureBorrowAssets, data.futureBorrowAssets, data.futureRewardBorrowAssets
            );

            deltaState.deltaUserFutureRewardBorrowAssets =
            calculateDeltaUserFutureRewardBorrowAssetsFromDeltaFutureRewardBorrowAssets(
                deltaFutureRewardBorrowAssets, data.auctionStep, data.auctionDuration
            );

            deltaState.deltaProtocolFutureRewardBorrowAssets =
                deltaFutureRewardBorrowAssets - deltaState.deltaUserFutureRewardBorrowAssets;

            deltaState.deltaUserBorrowAssets =
                deltaState.deltaFutureBorrowAssets + deltaState.deltaUserFutureRewardBorrowAssets;
        } else {
            deltaState.deltaFutureCollateralAssets = calculateDeltaFutureCollateralAssetsFromDeltaUserCollateralAssets(
                deltaState.deltaUserCollateralAssets,
                data.futureCollateralAssets,
                data.futureRewardCollateralAssets,
                data.auctionStep,
                data.auctionDuration
            );

            deltaState.deltaFutureBorrowAssets = calculateDeltaFutureBorrowAssetsFromDeltaFutureCollateralAssets(
                deltaState.deltaFutureCollateralAssets, data.futureBorrowAssets, data.futureCollateralAssets
            );
            deltaState.deltaUserBorrowAssets = deltaState.deltaFutureBorrowAssets;

            if (
                deltaState.deltaFutureBorrowAssets == -data.futureBorrowAssets
                    && deltaState.deltaFutureCollateralAssets != -data.futureCollateralAssets
            ) {
                deltaState.deltaFutureCollateralAssets = -data.futureCollateralAssets;

                int256 deltaFutureRewardCollateralAssets =
                calculateDeltaFutureRewardCollateralAssetsFromDeltaFutureCollateralAssets(
                    deltaState.deltaFutureCollateralAssets,
                    data.futureCollateralAssets,
                    data.futureRewardCollateralAssets
                );
                deltaState.deltaUserFutureRewardCollateralAssets =
                calculateDeltaUserFutureRewardCollateralAssetsFromDeltaFutureRewardCollateralAssets(
                    deltaFutureRewardCollateralAssets, data.auctionStep, data.auctionDuration
                );

                deltaState.deltaProtocolFutureRewardCollateralAssets =
                    deltaFutureRewardCollateralAssets - deltaState.deltaUserFutureRewardCollateralAssets;
            } else {
                int256 deltaFutureRewardCollateralAssets =
                calculateDeltaFutureRewardCollateralAssetsFromDeltaFutureCollateralAssets(
                    deltaState.deltaFutureCollateralAssets,
                    data.futureCollateralAssets,
                    data.futureRewardCollateralAssets
                );

                deltaState.deltaUserFutureRewardCollateralAssets =
                    deltaState.deltaUserCollateralAssets - deltaState.deltaFutureCollateralAssets;

                deltaState.deltaProtocolFutureRewardCollateralAssets =
                    deltaFutureRewardCollateralAssets - deltaState.deltaUserFutureRewardCollateralAssets;
            }
        }

        require(
            deltaState.deltaUserCollateralAssets
                <= deltaState.deltaFutureCollateralAssets + deltaState.deltaUserFutureRewardCollateralAssets,
            IAuctionErrors.UnexpectedDeltaUserCollateralAssets(
                deltaState.deltaUserCollateralAssets,
                deltaState.deltaFutureCollateralAssets + deltaState.deltaUserFutureRewardCollateralAssets
            )
        );

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
            int256 availableBorrowAssets = availableDeltaUserBorrowAssets(
                data.futureRewardBorrowAssets, data.auctionStep, data.auctionDuration, data.futureBorrowAssets
            );
            deltaWithinAuctionSize = (availableBorrowAssets > 0 && availableBorrowAssets >= -deltaUserBorrowAssets)
                || (availableBorrowAssets < 0 && availableBorrowAssets <= -deltaUserBorrowAssets);
        }
        require(
            hasOppositeSign && deltaWithinAuctionSize,
            IAuctionErrors.NoAuctionForProvidedDeltaFutureBorrow(
                data.futureBorrowAssets, data.futureRewardBorrowAssets, deltaUserBorrowAssets
            )
        );

        DeltaAuctionState memory deltaState;

        deltaState.deltaUserBorrowAssets = deltaUserBorrowAssets;
        // in case negative auction is active, rewards are in borrow
        if (deltaUserBorrowAssets > 0) {
            deltaState.deltaFutureBorrowAssets = calculateDeltaFutureBorrowAssetsFromDeltaUserBorrowAssets(
                deltaState.deltaUserBorrowAssets,
                data.futureBorrowAssets,
                data.futureRewardBorrowAssets,
                data.auctionStep,
                data.auctionDuration
            );

            deltaState.deltaFutureCollateralAssets = calculateDeltaFutureCollateralAssetsFromDeltaFutureBorrowAssets(
                deltaState.deltaFutureBorrowAssets, data.futureCollateralAssets, data.futureBorrowAssets
            );
            deltaState.deltaUserCollateralAssets = deltaState.deltaFutureCollateralAssets;

            if (
                deltaState.deltaFutureCollateralAssets == -data.futureCollateralAssets
                    && deltaState.deltaFutureBorrowAssets != -data.futureBorrowAssets
            ) {
                deltaState.deltaFutureBorrowAssets = -data.futureBorrowAssets;
                int256 deltaFutureRewardBorrowAssets = calculateDeltaFutureRewardBorrowAssetsFromDeltaFutureBorrowAssets(
                    deltaState.deltaFutureBorrowAssets, data.futureBorrowAssets, data.futureRewardBorrowAssets
                );
                deltaState.deltaUserFutureRewardBorrowAssets =
                calculateDeltaUserFutureRewardBorrowAssetsFromDeltaFutureRewardBorrowAssets(
                    deltaFutureRewardBorrowAssets, data.auctionStep, data.auctionDuration
                );
                deltaState.deltaProtocolFutureRewardBorrowAssets =
                    deltaFutureRewardBorrowAssets - deltaState.deltaUserFutureRewardBorrowAssets;
            } else {
                int256 deltaFutureRewardBorrowAssets = calculateDeltaFutureRewardBorrowAssetsFromDeltaFutureBorrowAssets(
                    deltaState.deltaFutureBorrowAssets, data.futureBorrowAssets, data.futureRewardBorrowAssets
                );
                deltaState.deltaUserFutureRewardBorrowAssets =
                    deltaState.deltaUserBorrowAssets - deltaState.deltaFutureBorrowAssets;
                deltaState.deltaProtocolFutureRewardBorrowAssets =
                    deltaFutureRewardBorrowAssets - deltaState.deltaUserFutureRewardBorrowAssets;
            }
        } else {
            deltaState.deltaFutureBorrowAssets = deltaUserBorrowAssets;
            deltaState.deltaFutureCollateralAssets = calculateDeltaFutureCollateralAssetsFromDeltaFutureBorrowAssets(
                deltaState.deltaFutureBorrowAssets, data.futureCollateralAssets, data.futureBorrowAssets
            );

            if (deltaState.deltaFutureCollateralAssets == -data.futureCollateralAssets) {
                deltaState.deltaFutureBorrowAssets = -data.futureBorrowAssets;
            }

            int256 deltaFutureRewardCollateralAssets =
            calculateDeltaFutureRewardCollateralAssetsFromDeltaFutureCollateralAssets(
                deltaState.deltaFutureCollateralAssets, data.futureCollateralAssets, data.futureRewardCollateralAssets
            );
            deltaState.deltaUserFutureRewardCollateralAssets =
            calculateDeltaUserFutureRewardCollateralAssetsFromDeltaFutureRewardCollateralAssets(
                deltaFutureRewardCollateralAssets, data.auctionStep, data.auctionDuration
            );

            deltaState.deltaProtocolFutureRewardCollateralAssets =
                deltaFutureRewardCollateralAssets - deltaState.deltaUserFutureRewardCollateralAssets;

            deltaState.deltaUserCollateralAssets =
                deltaState.deltaFutureCollateralAssets + deltaState.deltaUserFutureRewardCollateralAssets;
        }

        require(
            deltaState.deltaUserBorrowAssets
                >= deltaState.deltaFutureBorrowAssets + deltaState.deltaUserFutureRewardBorrowAssets,
            IAuctionErrors.UnexpectedDeltaUserBorrowAssets(
                deltaState.deltaUserBorrowAssets,
                deltaState.deltaFutureBorrowAssets + deltaState.deltaUserFutureRewardBorrowAssets
            )
        );

        return deltaState;
    }
}
