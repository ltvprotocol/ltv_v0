// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../Structs.sol";

library NextStep {

    // futureBorrow i+1 = futureBorrow i + ∆futureBorrow
    // futureCollateral i+1 = futureCollateral i + ∆futureCollateral
    // futureRewardBorrow i+1 = futureRewardBorrow i + ∆futurePaymentBorrow +
    //                                               + ∆userFutureRewardBorrow +
    //                                               + ∆protocolFutureRewardBorrow
    // futureRewardCollateral i+1 = futureRewardCollateral i + ∆futurePaymentCollateral +
    //                                                       + ∆userFutureRewardCollateral +
    //                                                       + ∆protocolFutureRewardCollateral

    function calculateNextFutureRewardBorrow(
        int256 futureRewardBorrow,
        int256 deltaFuturePaymentBorrow,
        int256 deltaUserFutureRewardBorrow,
        int256 deltaProtocolFutureRewardBorrow
    ) private pure returns (int256 nextFutureRewardBorrow) {
        return futureRewardBorrow + deltaFuturePaymentBorrow + deltaUserFutureRewardBorrow + deltaProtocolFutureRewardBorrow;
    }

    function calculateNextFutureRewardCollateral(
        int256 futureRewardCollateral,
        int256 deltaFuturePaymentCollateral,
        int256 deltaUserFutureRewardCollateral,
        int256 deltaProtocolFutureRewardCollateral
    ) private pure returns (int256 nextFutureRewardCollateral) {
        return futureRewardCollateral + deltaFuturePaymentCollateral + deltaUserFutureRewardCollateral + deltaProtocolFutureRewardCollateral;
    }

    function calculateNextFutureBorrow(
        int256 futureBorrow,
        int256 deltaFutureBorrow
    ) private pure returns (int256 nextFutureBorrow) {
        return futureBorrow + deltaFutureBorrow;
    }

    function calculateNextFutureCollateral(
        int256 futureCollateral,
        int256 deltaFutureCollateral
    ) private pure returns (int256 nextFutureCollateral) {
        return futureCollateral + deltaFutureCollateral;
    }

    function mergingAuction(
        ConvertedAssets memory convertedAssets,
        DeltaFuture memory deltaFuture,
        uint256 blockNumber
    ) private pure returns (uint256 startAuction, bool merge) {
        merge = convertedAssets.futureBorrow * deltaFuture.deltaFutureBorrow > 0 &&
                     convertedAssets.futureCollateral * deltaFuture.deltaFutureCollateral > 0;

        int auctionWeight = 0;
        if(convertedAssets.futureRewardBorrow != 0) {
            auctionWeight = convertedAssets.futureRewardBorrow;
        }
        if(convertedAssets.futureRewardCollateral != 0) {
            auctionWeight = convertedAssets.futureRewardCollateral;
        }

        int deltaAuctionWeight = 0;
        if(deltaFuture.deltaFuturePaymentBorrow != 0) {
            deltaAuctionWeight = deltaFuture.deltaFuturePaymentBorrow;
        }
        if(deltaFuture.deltaFuturePaymentCollateral != 0) {
            deltaAuctionWeight = deltaFuture.deltaFuturePaymentCollateral;
        }

        if (merge) {
            // TODO: think about Up or Down
            uint256 nextAuctionStep;
            if (auctionWeight + deltaAuctionWeight == 0) {
                nextAuctionStep = 0;
            } else {
                nextAuctionStep = uint256((convertedAssets.auctionStep * auctionWeight) / (auctionWeight + deltaAuctionWeight));
            }
            startAuction = blockNumber - nextAuctionStep;
        }
    }

    function calculateNextStep(
        ConvertedAssets memory convertedAssets,
        DeltaFuture memory deltaFuture,
        uint256 blockNumber
    ) internal pure returns (NextState memory nextState) {
        nextState.futureBorrow = calculateNextFutureBorrow(convertedAssets.futureBorrow, deltaFuture.deltaFutureBorrow);
        nextState.futureCollateral = calculateNextFutureCollateral(convertedAssets.futureCollateral, deltaFuture.deltaFutureCollateral);
        nextState.futureRewardBorrow = calculateNextFutureRewardBorrow(
            convertedAssets.futureRewardBorrow,
            deltaFuture.deltaFuturePaymentBorrow,
            deltaFuture.deltaUserFutureRewardBorrow,
            deltaFuture.deltaProtocolFutureRewardBorrow
        );
        nextState.futureRewardCollateral = calculateNextFutureRewardCollateral(
            convertedAssets.futureRewardCollateral,
            deltaFuture.deltaFuturePaymentCollateral,
            deltaFuture.deltaUserFutureRewardCollateral,
            deltaFuture.deltaProtocolFutureRewardCollateral
        );
        (nextState.startAuction, nextState.merge) = mergingAuction(convertedAssets, deltaFuture, blockNumber);
    }

}
