// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../structs/state_transition/NextState.sol";
import "../structs/state_transition/NextStateData.sol";
import "../structs/state_transition/NextStepData.sol";
import "../utils/MulDiv.sol";

library NextStep {
    using sMulDiv for int256;
    using uMulDiv for uint256;
    // futureBorrow i+1 = futureBorrow i + ∆futureBorrow
    // futureCollateral i+1 = futureCollateral i + ∆futureCollateral
    // futureRewardBorrow i+1 = futureRewardBorrow i + ∆futurePaymentBorrow +
    //                                               + ∆userFutureRewardBorrow +
    //                                               + ∆protocolFutureRewardBorrow
    // futureRewardCollateral i+1 = futureRewardCollateral i + ∆futurePaymentCollateral +
    //                                                       + ∆userFutureRewardCollateral +
    //                                                       + ∆protocolFutureRewardCollateral

    struct MergeAuctionData {
        int256 futureBorrow;
        int256 futureCollateral;
        int256 futureRewardBorrow;
        int256 futureRewardCollateral;
        int256 deltaFutureBorrow;
        int256 deltaFutureCollateral;
        uint24 auctionStep;
        int256 deltaFuturePaymentBorrow;
        int256 deltaFuturePaymentCollateral;
        uint56 blockNumber;
    }

    function calculateNextFutureRewardBorrow(
        int256 futureRewardBorrow,
        int256 deltaFuturePaymentBorrow,
        int256 deltaUserFutureRewardBorrow,
        int256 deltaProtocolFutureRewardBorrow
    ) private pure returns (int256 nextFutureRewardBorrow) {
        return futureRewardBorrow + deltaFuturePaymentBorrow + deltaUserFutureRewardBorrow
            + deltaProtocolFutureRewardBorrow;
    }

    function calculateNextFutureRewardCollateral(
        int256 futureRewardCollateral,
        int256 deltaFuturePaymentCollateral,
        int256 deltaUserFutureRewardCollateral,
        int256 deltaProtocolFutureRewardCollateral
    ) private pure returns (int256 nextFutureRewardCollateral) {
        return futureRewardCollateral + deltaFuturePaymentCollateral + deltaUserFutureRewardCollateral
            + deltaProtocolFutureRewardCollateral;
    }

    function calculateNextFutureBorrow(int256 futureBorrow, int256 deltaFutureBorrow)
        private
        pure
        returns (int256 nextFutureBorrow)
    {
        return futureBorrow + deltaFutureBorrow;
    }

    function calculateNextFutureCollateral(int256 futureCollateral, int256 deltaFutureCollateral)
        private
        pure
        returns (int256 nextFutureCollateral)
    {
        return futureCollateral + deltaFutureCollateral;
    }

    function mergingAuction(MergeAuctionData memory data) private pure returns (uint56 startAuction, bool merge) {
        merge =
            data.futureBorrow * data.deltaFutureBorrow >= 0 && data.futureCollateral * data.deltaFutureCollateral >= 0;

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

        if (merge) {
            uint24 nextAuctionStep;
            if (auctionWeight + deltaAuctionWeight == 0) {
                nextAuctionStep = data.auctionStep;
            } else {
                // round down to make auction longer
                nextAuctionStep = uint24(
                    uint256(
                        int256(uint256(data.auctionStep)).mulDivDown(auctionWeight, auctionWeight + deltaAuctionWeight)
                    )
                );
            }
            startAuction = data.blockNumber - nextAuctionStep;
        }
    }

    function calculateNextStep(NextStepData memory data) internal pure returns (NextState memory nextState) {
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
        (nextState.startAuction, nextState.merge) = mergingAuction(
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
    }
}
