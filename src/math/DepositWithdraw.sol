// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../Constants.sol";
import "./deltaFutureCollateral/DeltaRealBorrowAndDeltaRealCollateral.sol";
import "../utils/MulDiv.sol";
import "./CommonBorrowCollateral.sol";
import "../structs/data/vault/DepositWithdrawData.sol";
import "../structs/state_transition/DeltaFuture.sol";
import "../structs/data/vault/Cases.sol";
import "src/math/CasesOperator.sol";

library DepositWithdraw {
    using uMulDiv for uint256;
    using sMulDiv for int256;

    function calculateDepositWithdraw(DepositWithdrawData memory data)
        public
        pure
        returns (int256 sharesAsAssets, DeltaFuture memory deltaFuture)
    {
        Cases memory cases = CasesOperator.generateCase(0);

        (deltaFuture.deltaFutureCollateral, cases) = DeltaRealBorrowAndDeltaRealCollateral
            .calculateDeltaFutureCollateralByDeltaRealBorrowAndDeltaRealCollateral(
            DeltaRealBorrowAndDeltaRealCollateralData({
                cases: cases,
                borrow: data.borrow,
                collateral: data.collateral,
                protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                userFutureRewardBorrow: data.userFutureRewardBorrow,
                userFutureRewardCollateral: data.userFutureRewardCollateral,
                futureBorrow: data.futureBorrow,
                futureCollateral: data.futureCollateral,
                borrowSlippage: data.borrowSlippage,
                collateralSlippage: data.collateralSlippage,
                targetLTVDividend: data.targetLTVDividend,
                targetLTVDivider: data.targetLTVDivider,
                deltaRealCollateral: data.deltaRealCollateral,
                deltaRealBorrow: data.deltaRealBorrow
            })
        );

        // ∆shares = ∆userCollateral − ∆userBorrow
        // ∆userCollateral = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral
        // ∆userBorrow = ∆realBorrow + ∆futureBorrow + ∆userFutureRewardBorrow + ∆futurePaymentBorrow

        deltaFuture.deltaFutureBorrow = CommonBorrowCollateral.calculateDeltaFutureBorrowFromDeltaFutureCollateral(
            cases, data.futureCollateral, data.futureBorrow, deltaFuture.deltaFutureCollateral
        );

        deltaFuture.deltaUserFutureRewardCollateral = CommonBorrowCollateral.calculateDeltaUserFutureRewardCollateral(
            cases, data.futureCollateral, data.userFutureRewardCollateral, deltaFuture.deltaFutureCollateral
        );

        deltaFuture.deltaProtocolFutureRewardCollateral = CommonBorrowCollateral
            .calculateDeltaProtocolFutureRewardCollateral(
            cases, data.futureCollateral, data.protocolFutureRewardCollateral, deltaFuture.deltaFutureCollateral
        );

        deltaFuture.deltaFuturePaymentCollateral = CommonBorrowCollateral.calculateDeltaFuturePaymentCollateral(
            cases, data.futureCollateral, deltaFuture.deltaFutureCollateral, data.collateralSlippage
        );

        deltaFuture.deltaUserFutureRewardBorrow = CommonBorrowCollateral.calculateDeltaUserFutureRewardBorrow(
            cases, data.futureBorrow, data.userFutureRewardBorrow, deltaFuture.deltaFutureBorrow
        );

        deltaFuture.deltaProtocolFutureRewardBorrow = CommonBorrowCollateral.calculateDeltaProtocolFutureRewardBorrow(
            cases, data.futureBorrow, data.protocolFutureRewardBorrow, deltaFuture.deltaFutureBorrow
        );

        deltaFuture.deltaFuturePaymentBorrow = CommonBorrowCollateral.calculateDeltaFuturePaymentBorrow(
            cases, data.futureBorrow, deltaFuture.deltaFutureBorrow, data.borrowSlippage
        );

        sharesAsAssets = data.deltaRealCollateral + deltaFuture.deltaFutureCollateral
            + deltaFuture.deltaUserFutureRewardCollateral + deltaFuture.deltaFuturePaymentCollateral - data.deltaRealBorrow
            - deltaFuture.deltaFutureBorrow - deltaFuture.deltaUserFutureRewardBorrow - deltaFuture.deltaFuturePaymentBorrow;
    }
}
