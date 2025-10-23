// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {NextState} from "src/structs/state_transition/NextState.sol";
import {NextStepData} from "src/structs/state_transition/NextStepData.sol";
import {MergeAuctionData} from "src/structs/data/vault/common/MergeAuctionData.sol";
import {SMulDiv, UMulDiv} from "src/math/libraries/MulDiv.sol";

library NextStep {
    using SMulDiv for int256;
    using UMulDiv for uint256;
    // futureBorrow i+1 = futureBorrow i + ∆futureBorrow
    // futureCollateral i+1 = futureCollateral i + ∆futureCollateral
    // futureRewardBorrow i+1 = futureRewardBorrow i + ∆futurePaymentBorrow +
    //                                               + ∆userFutureRewardBorrow +
    //                                               + ∆protocolFutureRewardBorrow
    // futureRewardCollateral i+1 = futureRewardCollateral i + ∆futurePaymentCollateral +
    //                                                       + ∆userFutureRewardCollateral +
    //                                                       + ∆protocolFutureRewardCollateral

    /**
     * @notice Calculates next future reward borrow.
     *
     * @dev Calculations are derived from the ltv protocol paper.
     * Hint: simple sum of all the changes.
     */
    function calculateNextFutureRewardBorrow(
        int256 futureRewardBorrow,
        int256 deltaFuturePaymentBorrow,
        int256 deltaUserFutureRewardBorrow,
        int256 deltaProtocolFutureRewardBorrow
    ) private pure returns (int256 nextFutureRewardBorrow) {
        return futureRewardBorrow + deltaFuturePaymentBorrow + deltaUserFutureRewardBorrow
            + deltaProtocolFutureRewardBorrow;
    }

    /**
     * @notice Calculates next future reward collateral.
     *
     * @dev Calculations are derived from the ltv protocol paper.
     * Hint: simple sum of all the changes.
     */
    function calculateNextFutureRewardCollateral(
        int256 futureRewardCollateral,
        int256 deltaFuturePaymentCollateral,
        int256 deltaUserFutureRewardCollateral,
        int256 deltaProtocolFutureRewardCollateral
    ) private pure returns (int256 nextFutureRewardCollateral) {
        return futureRewardCollateral + deltaFuturePaymentCollateral + deltaUserFutureRewardCollateral
            + deltaProtocolFutureRewardCollateral;
    }

    /**
     * @notice Calculates next future borrow.
     *
     * @dev Calculations are derived from the ltv protocol paper.
     * Hint: simple sum of all the changes.
     */
    function calculateNextFutureBorrow(int256 futureBorrow, int256 deltaFutureBorrow)
        private
        pure
        returns (int256 nextFutureBorrow)
    {
        return futureBorrow + deltaFutureBorrow;
    }

    /**
     * @notice Calculates next future collateral.
     *
     * @dev Calculations are derived from the ltv protocol paper.
     * Hint: simple sum of all the changes.
     */
    function calculateNextFutureCollateral(int256 futureCollateral, int256 deltaFutureCollateral)
        private
        pure
        returns (int256 nextFutureCollateral)
    {
        return futureCollateral + deltaFutureCollateral;
    }

    /**
     * @notice Calculates next auction start point.
     *
     * @dev In case of auction merging, recalculates auction start point and returns true.
     * Otherwise returns 0 and false.
     */
    function mergingAuction(MergeAuctionData memory data) private pure returns (uint56 startAuction) {
        int256 auctionWeight = 0;
        if (data.futureRewardBorrow != 0) {
            auctionWeight = data.futureRewardBorrow;
        }
        if (data.futureRewardCollateral != 0) {
            auctionWeight = data.futureRewardCollateral;
        }

        int256 deltaAuctionWeight = 0;
        if (data.deltaFuturePaymentBorrow != 0) {
            deltaAuctionWeight = data.deltaFuturePaymentBorrow;
        }
        if (data.deltaFuturePaymentCollateral != 0) {
            deltaAuctionWeight = data.deltaFuturePaymentCollateral;
        }

        uint24 nextAuctionStep;
        if (auctionWeight + deltaAuctionWeight == 0) {
            nextAuctionStep = data.auctionStep;
        } else {
            // round down to make auction longer
            nextAuctionStep = uint24(
                uint256(int256(uint256(data.auctionStep)).mulDivDown(auctionWeight, auctionWeight + deltaAuctionWeight))
            );
        }
        startAuction = data.blockNumber - nextAuctionStep;
    }

    /**
     * @notice Calculates next state using functions from this library.
     */
    function calculateNextStep(NextStepData memory data) external pure returns (NextState memory nextState) {
        nextState.futureBorrow = calculateNextFutureBorrow(data.futureBorrow, data.deltaFutureBorrow);
        nextState.futureCollateral = calculateNextFutureCollateral(data.futureCollateral, data.deltaFutureCollateral);
        nextState.futureRewardBorrow = calculateNextFutureRewardBorrow(
            data.futureRewardBorrow,
            data.deltaFuturePaymentBorrow,
            data.deltaUserFutureRewardBorrow,
            data.deltaProtocolFutureRewardBorrow
        );
        nextState.futureRewardCollateral = calculateNextFutureRewardCollateral(
            data.futureRewardCollateral,
            data.deltaFuturePaymentCollateral,
            data.deltaUserFutureRewardCollateral,
            data.deltaProtocolFutureRewardCollateral
        );

        if (data.cases.cmcb + data.cases.cmbc == 1) {
            nextState.startAuction = mergingAuction(
                MergeAuctionData({
                    futureBorrow: data.futureBorrow,
                    futureCollateral: data.futureCollateral,
                    futureRewardBorrow: data.futureRewardBorrow,
                    futureRewardCollateral: data.futureRewardCollateral,
                    deltaFutureBorrow: data.deltaFutureBorrow,
                    deltaFutureCollateral: data.deltaFutureCollateral,
                    auctionStep: data.auctionStep,
                    deltaFuturePaymentBorrow: data.deltaFuturePaymentBorrow,
                    deltaFuturePaymentCollateral: data.deltaFuturePaymentCollateral,
                    blockNumber: data.blockNumber
                })
            );
        } else if (data.cases.ceccb + data.cases.cecbc == 1) {
            nextState.startAuction = data.blockNumber;
        } else {
            nextState.startAuction = type(uint56).max;
        }
    }
}
