// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../State.sol';
import '../Constants.sol';
import '../Structs.sol';
import '../Cases.sol';
import './deltaFutureCollateral/DeltaRealBorrowAndDeltaRealCollateral.sol';
import '../utils/MulDiv.sol';
import './CommonBorrowCollateral.sol';

library DepositWithdraw {
    function calculateDepositWithdraw(
        int256 assets,
        bool isBorrowAssets,
        ConvertedAssets memory convertedAssets,
        Prices memory prices,
        uint128 targetLTV
    ) public pure returns (int256 sharesAsAssets, DeltaFuture memory deltaFuture) {
        int256 deltaRealBorrow = isBorrowAssets ? assets * int256(prices.borrow / Constants.ORACLE_DIVIDER) : int256(0);
        int256 deltaRealCollateral = isBorrowAssets ? int256(0) : assets * int256(prices.collateral / Constants.ORACLE_DIVIDER);

        Cases memory cases = CasesOperator.generateCase(0);

        (deltaFuture.deltaFutureCollateral, cases) = DeltaRealBorrowAndDeltaRealCollateral
            .calculateDeltaFutureCollateralByDeltaRealBorrowAndDeltaRealCollateral(
                prices,
                convertedAssets,
                cases,
                deltaRealCollateral,
                deltaRealBorrow,
                targetLTV
            );

        // ∆shares = ∆userCollateral − ∆userBorrow
        // ∆userCollateral = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral
        // ∆userBorrow = ∆realBorrow + ∆futureBorrow + ∆userFutureRewardBorrow + ∆futurePaymentBorrow

        deltaFuture.deltaFutureBorrow = CommonBorrowCollateral.calculateDeltaFutureBorrowFromDeltaFutureCollateral(
            cases,
            convertedAssets,
            deltaFuture.deltaFutureCollateral
        );

        deltaFuture.deltaUserFutureRewardCollateral = CommonBorrowCollateral.calculateDeltaUserFutureRewardCollateral(
            cases,
            convertedAssets,
            deltaFuture.deltaFutureCollateral
        );

        deltaFuture.deltaProtocolFutureRewardCollateral = CommonBorrowCollateral.calculateDeltaProtocolFutureRewardCollateral(
            cases,
            convertedAssets,
            deltaFuture.deltaFutureCollateral
        );

        deltaFuture.deltaFuturePaymentCollateral = CommonBorrowCollateral.calculateDeltaFuturePaymentCollateral(
            cases,
            convertedAssets,
            deltaFuture.deltaFutureCollateral,
            prices.collateralSlippage
        );

        deltaFuture.deltaUserFutureRewardBorrow = CommonBorrowCollateral.calculateDeltaUserFutureRewardBorrow(
            cases,
            convertedAssets,
            deltaFuture.deltaFutureBorrow
        );

        deltaFuture.deltaProtocolFutureRewardBorrow = CommonBorrowCollateral.calculateDeltaProtocolFutureRewardBorrow(
            cases,
            convertedAssets,
            deltaFuture.deltaFutureBorrow
        );

        deltaFuture.deltaFuturePaymentBorrow = CommonBorrowCollateral.calculateDeltaFuturePaymentBorrow(
            cases,
            convertedAssets,
            deltaFuture.deltaFutureBorrow,
            prices.borrowSlippage
        );

        sharesAsAssets =
            deltaRealCollateral +
            deltaFuture.deltaFutureCollateral +
            deltaFuture.deltaUserFutureRewardCollateral +
            deltaFuture.deltaFuturePaymentCollateral -
            deltaRealBorrow -
            deltaFuture.deltaFutureBorrow -
            deltaFuture.deltaUserFutureRewardBorrow -
            deltaFuture.deltaFuturePaymentBorrow;
    }

    function previewDepositWithdraw(
        int256 assets,
        bool isBorrowAssets,
        ConvertedAssets memory convertedAssets,
        Prices memory prices,
        uint128 targetLTV
    ) external pure returns (int256 sharesAsAssets) {
        (sharesAsAssets, ) = calculateDepositWithdraw(assets, isBorrowAssets, convertedAssets, prices, targetLTV);
    }
}
