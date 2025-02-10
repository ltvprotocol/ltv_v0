// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "../Cases.sol";
import "../RealBorrowAndRealCollateral.sol";
import "../utils/MulDiv.sol";

abstract contract CommonBorrowCollateral is State {

    using uMulDiv for uint256;

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

        deltaFutureBorrow += int256(int8(ncase.cecb + ncase.cebc)) * deltaFutureCollateral * convertedAssets.futureBorrow / convertedAssets.futureCollateral;
        deltaFutureBorrow += int256(int8(ncase.ceccb + ncase.cecbc)) * (convertedAssets.futureCollateral - convertedAssets.futureBorrow);

        return deltaFutureBorrow;
    }

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
        
        int256 deltaUserFutureRewardCollateral = int256(int8(ncase.cecb)) * convertedAssets.userFutureRewardCollateral * deltaFutureCollateral / convertedAssets.futureCollateral;
        deltaUserFutureRewardCollateral -= int256(int8(ncase.ceccb)) * convertedAssets.userFutureRewardCollateral;
        return deltaUserFutureRewardCollateral;
    }

    function calculateDeltaFuturePaymentCollateral(
        Cases memory ncase,
        ConvertedAssets memory convertedAssets,
        int256 deltaFutureCollateral
    ) internal view returns (int256) {

        // cmbc × −∆futureCollateral × collateralSlippage +
        // + cecbc × −(∆futureCollateral + futureCollateral) × collateralSlippage

        int256 deltaFuturePaymentCollateral = -int256(int8(ncase.cmbc)) * deltaFutureCollateral * int256(getPrices().collateralSlippage);
        deltaFuturePaymentCollateral -= int256(int8(ncase.cecbc)) * (deltaFutureCollateral + convertedAssets.futureCollateral) * int256(getPrices().collateralSlippage);

        deltaFuturePaymentCollateral = deltaFuturePaymentCollateral / 10**18;

        return deltaFuturePaymentCollateral;
    }

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

        int256 deltaUserFutureRewardBorrow = int256(int8(ncase.cebc)) * convertedAssets.userFutureRewardBorrow * deltaFutureBorrow / convertedAssets.futureBorrow;
        deltaUserFutureRewardBorrow -= int256(int8(ncase.cecbc)) * convertedAssets.userFutureRewardBorrow;
        
        return deltaUserFutureRewardBorrow;
    }

    function calculateDeltaFuturePaymentBorrow(
        Cases memory ncase,
        ConvertedAssets memory convertedAssets,
        int256 deltaFutureBorrow
    ) internal view returns (int256) {
        // cmcb × −∆futureBorrow × borrowSlippage +
        // + ceccb × −(∆futureBorrow + futureBorrow) × borrowSlippage

        int256 deltaFuturePaymentBorrow = -int256(int8(ncase.cmcb)) * deltaFutureBorrow * int256(getPrices().borrowSlippage);
        deltaFuturePaymentBorrow -= int256(int8(ncase.ceccb)) * (deltaFutureBorrow + convertedAssets.futureBorrow) * int256(getPrices().borrowSlippage);

        deltaFuturePaymentBorrow = deltaFuturePaymentBorrow / 10 ** 18;

        return deltaFuturePaymentBorrow;
    }
}
