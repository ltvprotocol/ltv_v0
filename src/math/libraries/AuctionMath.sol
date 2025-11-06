// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IAuctionErrors} from "../../errors/IAuctionErrors.sol";
import {AuctionData} from "../../structs/data/auction/AuctionData.sol";
import {DeltaAuctionState} from "../../structs/state_transition/DeltaAuctionState.sol";
import {SMulDiv} from "./MulDiv.sol";

/**
 * @title AuctionMath
 * @notice This library contains functions to calculate deltaFutureBorrowAssets and deltaFutureCollateralAssets.
 *
 * @dev These calculations are derived from the ltv protocol paper.
 * ROUNDING:
 * since auction execution doesn't affect totalAssets we have only two conflicts here,
 * executor <=> future executor,
 * executor <=> fee collector
 */
library AuctionMath {
    using SMulDiv for int256;

    /**
     * @notice This function calculates deltaFutureBorrowAssets from deltaUserBorrowAssets.
     *
     * @dev This function calculates deltaFutureBorrowAssets from deltaUserBorrowAssets.
     * Calculations are derived from the ltv protocol paper.
     *
     * ROUNDING:
     * delta future borrow needs to be rounded down to make auction reward bigger for future executor
     */
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

    /**
     * @notice This function calculates deltaFutureCollateralAssets from deltaUserCollateralAssets.
     *
     * @dev This function calculates deltaFutureCollateralAssets from deltaUserCollateralAssets.
     * Calculations are derived from the ltv protocol paper.
     *
     * ROUNDING:
     * delta future collateral needs to be rounded up to make rewards bigger for future executor
     */
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

    /**
     * @notice This function calculates deltaFutureBorrowAssets from deltaFutureCollateralAssets.
     *
     * @dev This function calculates deltaFutureBorrowAssets from deltaFutureCollateralAssets.
     * Calculations are derived from the ltv protocol paper. Hint: auction execution
     * has to be proportional
     *
     * ROUNDING:
     * delta future borrow needs to be rounded up to make auction more profitable for future executor
     */
    function calculateDeltaFutureBorrowAssetsFromDeltaFutureCollateralAssets(
        int256 deltaFutureCollateralAssets,
        int256 futureBorrowAssets,
        int256 futureCollateralAssets
    ) private pure returns (int256) {
        return deltaFutureCollateralAssets.mulDivUp(futureBorrowAssets, futureCollateralAssets);
    }

    /**
     * @notice This function calculates deltaFutureCollateralAssets from deltaFutureBorrowAssets.
     *
     * @dev This function calculates deltaFutureCollateralAssets from deltaFutureBorrowAssets.
     * Calculations are derived from the ltv protocol paper. Hint: auction execution
     * has to be proportional
     *
     * ROUNDING:
     * delta future collateral needs to be rounded down to make auction more profitable for future executor
     */
    function calculateDeltaFutureCollateralAssetsFromDeltaFutureBorrowAssets(
        int256 deltaFutureBorrowAssets,
        int256 futureCollateralAssets,
        int256 futureBorrowAssets
    ) private pure returns (int256) {
        return deltaFutureBorrowAssets.mulDivDown(futureCollateralAssets, futureBorrowAssets);
    }

    /**
     * @notice This function calculates deltaFutureRewardBorrowAssets from deltaFutureBorrowAssets.
     *
     * @dev This function calculates deltaFutureRewardBorrowAssets from deltaFutureBorrowAssets.
     * Calculations are derived from the ltv protocol paper. Hint: substracted rewards also
     * need to be proportional to the auction execution size.
     *
     * ROUNDING:
     * needs to be rounded up to make auction more profitable for future executor
     */
    function calculateDeltaFutureRewardBorrowAssetsFromDeltaFutureBorrowAssets(
        int256 deltaFutureBorrowAssets,
        int256 futureBorrowAssets,
        int256 futureRewardBorrowAssets
    ) private pure returns (int256) {
        return futureRewardBorrowAssets.mulDivUp(deltaFutureBorrowAssets, futureBorrowAssets);
    }

    /**
     * @notice This function calculates deltaFutureRewardCollateralAssets from deltaFutureCollateralAssets.
     *
     * @dev This function calculates deltaFutureRewardCollateralAssets from deltaFutureCollateralAssets.
     * Calculations are derived from the ltv protocol paper. Hint: substracted rewards also
     * need to be proportional to the auction execution size.
     *
     * ROUNDING:
     * needs to be rounded down to make auction more profitable for future executor
     */
    function calculateDeltaFutureRewardCollateralAssetsFromDeltaFutureCollateralAssets(
        int256 deltaFutureCollateralAssets,
        int256 futureCollateralAssets,
        int256 futureRewardCollateralAssets
    ) private pure returns (int256) {
        return futureRewardCollateralAssets.mulDivDown(deltaFutureCollateralAssets, futureCollateralAssets);
    }

    /**
     * @notice This function calculates deltaUserFutureRewardBorrowAssets from deltaFutureRewardBorrowAssets.
     *
     * @dev This function calculates deltaUserFutureRewardBorrowAssets from deltaFutureRewardBorrowAssets.
     * Calculations are derived from the ltv protocol paper. Hint: user has only part of the distributed rewards.
     * It depends on the auction size and current auction step.
     *
     * ROUNDING:
     * Fee collector and auction executor conflict. Resolve to give more to auction executor
     */
    function calculateDeltaUserFutureRewardBorrowAssetsFromDeltaFutureRewardBorrowAssets(
        int256 deltaFutureRewardBorrowAssets,
        uint24 auctionStep,
        uint24 auctionDuration
    ) private pure returns (int256) {
        return deltaFutureRewardBorrowAssets.mulDivDown(int256(uint256(auctionStep)), int256(uint256(auctionDuration)));
    }

    /**
     * @notice This function calculates deltaUserFutureRewardCollateralAssets from deltaFutureRewardCollateralAssets.
     *
     * @dev This function calculates deltaUserFutureRewardCollateralAssets from deltaFutureRewardCollateralAssets.
     * Calculations are derived from the ltv protocol paper. Hint: user has only part of the distributed rewards.
     * It depends on the auction size and current auction step.
     *
     * ROUNDING:
     * Fee collector and auction executor conflict. Resolve to give more to auction executor
     */
    function calculateDeltaUserFutureRewardCollateralAssetsFromDeltaFutureRewardCollateralAssets(
        int256 deltaFutureRewardCollateralAssets,
        uint24 auctionStep,
        uint24 auctionDuration
    ) private pure returns (int256) {
        return
            deltaFutureRewardCollateralAssets.mulDivUp(int256(uint256(auctionStep)), int256(uint256(auctionDuration)));
    }

    /**
     * @notice This function calculates maximum possible deltaUserBorrowAssets for current auction state.
     *
     * @dev This function calculates availableDeltaUserBorrowAssets.
     * Calculations are derived from the ltv protocol paper. Hint: user can calculate an entire auction, but
     * rewards can reduce amount user will need to pay.
     *
     */
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

    /**
     * @notice This function calculates maximum possible deltaUserCollateralAssets for current auction state.
     *
     * @dev This function calculates availableDeltaUserCollateralAssets.
     * Calculations are derived from the ltv protocol paper. Hint: user can calculate an entire auction, but
     * rewards can reduce amount user will need to pay.
     */
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

    /**
     * @notice This function calculates full protocol state transition when executing auction providing
     * collateral assets.
     *
     * @dev Calculation checks if provided deltaUserCollateralAssets is valid for current auction state. After,
     * calculation uses functions described above to sequentially calculate an entire state change.
     * Depending on the direction of the auction, rewards are in borrow or collateral. It splits calculation
     * into two branches. Calculation also handles case where because of roundings, auction can request full
     * execution of borrow part in exchange for just part of the collateral part. It can make resulting state
     * invalid, since, for instance, futureBorrow will be 1, when futureCollateral will be 0. Function handles
     * this case and makes sure that either futureBorrow or futureCollateral are not 0 or both 0.
     *
     */
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

    /**
     * @notice This function calculates full protocol state transition when executing auction providing
     * borrow assets.
     *
     * @dev Calculation checks if provided deltaUserBorrowAssets is valid for current auction state. After,
     * calculation uses functions described above to sequentially calculate an entire state change.
     * Depending on the direction of the auction, rewards are in borrow or collateral. It splits calculation
     * into two branches. Calculation also handles case where because of roundings, auction can request full
     * execution of collateral part in exchange for just part of the borrow part. It can make resulting state
     * invalid, since, for instance, futureBorrow will be 1, when futureCollateral will be 0. Function handles
     * this case and makes sure that either futureBorrow or futureCollateral are not 0 or both 0.
     *
     */
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
