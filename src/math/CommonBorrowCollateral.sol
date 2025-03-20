// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../State.sol';
import '../Constants.sol';
import '../Structs.sol';
import '../Cases.sol';
import '../utils/MulDiv.sol';

library CommonBorrowCollateral {
    using uMulDiv for uint256;
    using sMulDiv for int256;

    // need to round it up to make better for protocol
    function calculateDeltaFutureBorrowFromDeltaFutureCollateral(
        Cases memory ncase,
        ConvertedAssets memory convertedAssets,
        int256 deltaFutureCollateral
    ) internal pure returns (int256) {
        // (cna + cmcb + cmbc + ceccb + cecbc) × ∆futureCollateral +
        // + (cecb + cebc) × ∆futureCollateral × futureBorrow / futureCollateral +
        // + (ceccb + cecbc) × (futureCollateral − futureBorrow)

        int256 deltaFutureBorrow = int256(int8(ncase.cna + ncase.cmcb + ncase.cmbc + ncase.ceccb + ncase.cecbc)) * deltaFutureCollateral;
        if (convertedAssets.futureCollateral == 0) {
            return deltaFutureBorrow;
        }

        deltaFutureBorrow +=
            int256(int8(ncase.cecb + ncase.cebc)) *
            deltaFutureCollateral.mulDivUp(convertedAssets.futureBorrow, convertedAssets.futureCollateral);
        deltaFutureBorrow += int256(int8(ncase.ceccb + ncase.cecbc)) * (convertedAssets.futureCollateral - convertedAssets.futureBorrow);

        return deltaFutureBorrow;
    }

    // need to round it down to make better for protocol
    function calculateDeltaFutureCollateralFromDeltaFutureBorrow(
        Cases memory ncase,
        ConvertedAssets memory convertedAssets,
        int256 deltaFutureBorrow
    ) internal pure returns (int256) {
        int256 deltaFutureCollateral = int256(int8(ncase.cna + ncase.cmcb + ncase.cmbc + ncase.ceccb + ncase.cecbc)) * deltaFutureBorrow;
        if (convertedAssets.futureCollateral == 0) {
            return deltaFutureCollateral;
        }

        deltaFutureCollateral +=
            int256(int8(ncase.cecb + ncase.cebc)) *
            deltaFutureBorrow.mulDivDown(convertedAssets.futureCollateral, convertedAssets.futureBorrow);
        deltaFutureCollateral += int256(int8(ncase.ceccb + ncase.cecbc)) * (convertedAssets.futureBorrow - convertedAssets.futureCollateral);

        return deltaFutureCollateral;
    }

    // round down to leave more rewards in protocol
    function calculateDeltaUserFutureRewardCollateral(
        Cases memory ncase,
        ConvertedAssets memory convertedAssets,
        int256 deltaFutureCollateral
    ) internal pure returns (int256) {
        // cecb × userFutureRewardCollateral × ∆futureCollateral / futureCollateral +
        // + ceccb × −userFutureRewardCollateral

        if (convertedAssets.futureCollateral == 0) {
            return 0;
        }

        int256 deltaUserFutureRewardCollateral = int256(int8(ncase.cecb)) *
            convertedAssets.userFutureRewardCollateral.mulDivDown(deltaFutureCollateral, convertedAssets.futureCollateral);
        deltaUserFutureRewardCollateral -= int256(int8(ncase.ceccb)) * convertedAssets.userFutureRewardCollateral;
        return deltaUserFutureRewardCollateral;
    }

    // round up, it'll positively affect the price
    function calculateDeltaProtocolFutureRewardCollateral(
        Cases memory ncase,
        ConvertedAssets memory convertedAssets,
        int256 deltaFutureCollateral
    ) internal pure returns (int256) {
        // cecb × userFutureRewardCollateral × ∆futureCollateral / futureCollateral +
        // + ceccb × −userFutureRewardCollateral

        if (convertedAssets.futureCollateral == 0) {
            return 0;
        }

        int256 deltaProtocolFutureRewardCollateral = (int256(int8(ncase.cecb)) *
            convertedAssets.protocolFutureRewardCollateral *
            deltaFutureCollateral) / convertedAssets.futureCollateral;
        deltaProtocolFutureRewardCollateral -= int256(int8(ncase.ceccb)) * convertedAssets.protocolFutureRewardCollateral;
        return deltaProtocolFutureRewardCollateral;
    }

    // round down to leave more rewards in protocol
    function calculateDeltaFuturePaymentCollateral(
        Cases memory ncase,
        ConvertedAssets memory convertedAssets,
        int256 deltaFutureCollateral,
        uint256 collateralSlippage
    ) internal pure returns (int256) {
        // cmbc × −∆futureCollateral × collateralSlippage +
        // + cecbc × −(∆futureCollateral + futureCollateral) × collateralSlippage

        int256 deltaFuturePaymentCollateral = -int256(int8(ncase.cmbc)) *
            deltaFutureCollateral.mulDivUp(int256(collateralSlippage), Constants.SLIPPAGE_PRECISION);
        deltaFuturePaymentCollateral -=
            int256(int8(ncase.cecbc)) *
            (deltaFutureCollateral + convertedAssets.futureCollateral).mulDivUp(int256(collateralSlippage), Constants.SLIPPAGE_PRECISION);

        return deltaFuturePaymentCollateral;
    }

    // round up to leave more rewards in protocol
    function calculateDeltaUserFutureRewardBorrow(
        Cases memory ncase,
        ConvertedAssets memory convertedAssets,
        int256 deltaFutureBorrow
    ) internal pure returns (int256) {
        // cebc × userF utureRewardBorrow × ∆futureBorrow / futureBorrow +
        // + cecbc × −userFutureRewardBorrow

        if (convertedAssets.futureBorrow == 0) {
            return 0;
        }

        int256 deltaUserFutureRewardBorrow = int256(int8(ncase.cebc)) *
            convertedAssets.userFutureRewardBorrow.mulDivUp(deltaFutureBorrow, convertedAssets.futureBorrow);
        deltaUserFutureRewardBorrow -= int256(int8(ncase.cecbc)) * convertedAssets.userFutureRewardBorrow;

        return deltaUserFutureRewardBorrow;
    }

    // round down, it'll positively affect the price
    function calculateDeltaProtocolFutureRewardBorrow(
        Cases memory ncase,
        ConvertedAssets memory convertedAssets,
        int256 deltaFutureBorrow
    ) internal pure returns (int256) {
        if (convertedAssets.futureBorrow == 0) {
            return 0;
        }

        int256 deltaProtocolFutureRewardBorrow = int256(int8(ncase.cebc)) *
            convertedAssets.protocolFutureRewardBorrow.mulDivDown(deltaFutureBorrow, convertedAssets.futureBorrow);
        deltaProtocolFutureRewardBorrow -= int256(int8(ncase.cecbc)) * convertedAssets.protocolFutureRewardBorrow;

        return deltaProtocolFutureRewardBorrow;
    }

    // round up to leave more rewards in protocol
    function calculateDeltaFuturePaymentBorrow(
        Cases memory ncase,
        ConvertedAssets memory convertedAssets,
        int256 deltaFutureBorrow,
        uint256 borrowSlippage
    ) internal pure returns (int256) {
        // cmcb × −∆futureBorrow × borrowSlippage +
        // + ceccb × −(∆futureBorrow + futureBorrow) × borrowSlippage

        int256 deltaFuturePaymentBorrow = -int256(int8(ncase.cmcb)) *
            deltaFutureBorrow.mulDivDown(int256(borrowSlippage), Constants.SLIPPAGE_PRECISION);
        deltaFuturePaymentBorrow -=
            int256(int8(ncase.ceccb)) *
            (deltaFutureBorrow + convertedAssets.futureBorrow).mulDivDown(int256(borrowSlippage), Constants.SLIPPAGE_PRECISION);

        return deltaFuturePaymentBorrow;
    }
}
