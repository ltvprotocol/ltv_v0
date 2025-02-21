// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "../Cases.sol";
import "./deltaFutureCollateral/DeltaRealBorrowAndDeltaRealCollateral.sol";
import "../utils/MulDiv.sol";
import "./CommonBorrowCollateral.sol";

abstract contract DepositWithdraw is CommonBorrowCollateral, DeltaRealBorrowAndDeltaRealCollateral {

    function calculateDepositWithdraw(int256 assets, bool isBorrowAssets) internal view returns (
        int256 sharesAsAssets,
        DeltaFuture memory deltaFuture
    ) {
        int256 deltaRealBorrow = isBorrowAssets ? assets * int256(getPriceBorrowOracle() / Constants.ORACLE_DIVIDER) : int256(0);
        int256 deltaRealCollateral = isBorrowAssets ? int256(0) : assets * int256(getPriceCollateralOracle() / Constants.ORACLE_DIVIDER);

        ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        Prices memory prices = getPrices();

        Cases memory cases = CasesOperator.generateCase(0);

        (deltaFuture.deltaFutureCollateral, cases) = calculateDeltaFutureCollateralByDeltaRealBorrowAndDeltaRealCollateral(prices, convertedAssets, cases, deltaRealCollateral, deltaRealBorrow);

        // ∆shares = ∆userCollateral − ∆userBorrow
        // ∆userCollateral = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral
        // ∆userBorrow = ∆realBorrow + ∆futureBorrow + ∆userFutureRewardBorrow + ∆futurePaymentBorrow

        deltaFuture.deltaFutureBorrow = calculateDeltaFutureBorrowFromDeltaFutureCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);

        deltaFuture.deltaUserFutureRewardCollateral = calculateDeltaUserFutureRewardCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);

        deltaFuture.deltaProtocolFutureRewardCollateral = calculateDeltaProtocolFutureRewardCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);

        deltaFuture.deltaFuturePaymentCollateral = calculateDeltaFuturePaymentCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);

        deltaFuture.deltaUserFutureRewardBorrow = calculateDeltaUserFutureRewardBorrow(cases, convertedAssets, deltaFuture.deltaFutureBorrow);

        deltaFuture.deltaProtocolFutureRewardBorrow = calculateDeltaProtocolFutureRewardBorrow(cases, convertedAssets, deltaFuture.deltaFutureBorrow);

        deltaFuture.deltaFuturePaymentBorrow = calculateDeltaFuturePaymentBorrow(cases, convertedAssets, deltaFuture.deltaFutureBorrow);

        sharesAsAssets = deltaRealCollateral
               + deltaFuture.deltaFutureCollateral
               + deltaFuture.deltaUserFutureRewardCollateral
               + deltaFuture.deltaFuturePaymentCollateral
               - deltaRealBorrow
               - deltaFuture.deltaFutureBorrow
               - deltaFuture.deltaUserFutureRewardBorrow
               - deltaFuture.deltaFuturePaymentBorrow;

    }

    function previewDepositWithdraw(int256 assets, bool isBorrowAssets) internal view returns (int256 sharesAsAssets) {

        (sharesAsAssets, ) = calculateDepositWithdraw(assets, isBorrowAssets);

    }

}
