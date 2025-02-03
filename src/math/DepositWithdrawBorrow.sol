// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "../Cases.sol";
import "./deltaFutureCollateral/DeltaRealBorrowAndDeltaRealCollateral.sol";
import "../utils/MulDiv.sol";
import "./CommonBorrowCollateral.sol";

abstract contract DepositWithdrawBorrow is State, DeltaRealBorrowAndDeltaRealCollateral, CommonBorrowCollateral {

    function calculateDepositWithdrawBorrow(int256 assets) internal view returns (
        int256 shares,
        DeltaFuture memory deltaFuture
    ) {

        int256 deltaRealBorrow = assets * int256(getPriceBorrowOracle() / Constants.ORACLE_DEVIDER);
        int256 deltaRealCollateral = 0;

        ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        Prices memory prices = getPrices();

        Cases memory cases = CasesOperator.generateCase(0);

        deltaFuture.deltaFutureCollateral = calculateDeltaFutureCollateralByDeltaRealBorrowAndDeltaRealCollateral(prices, convertedAssets, cases, deltaRealCollateral, deltaRealBorrow);

        // ∆shares = ∆userCollateral − ∆userBorrow
        // ∆userCollateral = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral
        // ∆userBorrow = ∆realBorrow + ∆futureBorrow + ∆userFutureRewardBorrow + ∆futurePaymentBorrow

        deltaFuture.deltaFutureBorrow = calculateDeltaFutureBorrowFromDeltaFutureCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);

        deltaFuture.deltaUserFutureRewardCollateral = calculateDeltaUserFutureRewardCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);

        deltaFuture.deltaFuturePaymentCollateral = calculateDeltaFuturePaymentCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);

        deltaFuture.deltaUserFutureRewardBorrow = calculateDeltaUserFutureRewardBorrow(cases, convertedAssets, deltaFuture.deltaFutureBorrow);

        deltaFuture.deltaFuturePaymentBorrow = calculateDeltaFuturePaymentBorrow(cases, convertedAssets, deltaFuture.deltaFutureBorrow);

        shares = deltaRealCollateral 
               + deltaFuture.deltaFutureCollateral
               + deltaFuture.deltaUserFutureRewardCollateral
               + deltaFuture.deltaFuturePaymentCollateral
               - deltaRealBorrow
               - deltaFuture.deltaFutureBorrow
               - deltaFuture.deltaUserFutureRewardBorrow
               - deltaFuture.deltaFuturePaymentBorrow;

    }

    function previewDepositWithdrawBorrow(int256 assets) internal view returns (int256 shares) {

        (shares, ) = calculateDepositWithdrawBorrow(assets);

    }

}
