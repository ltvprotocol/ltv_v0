// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {DeltaRealBorrowAndDeltaRealCollateralData} from
    "src/structs/data/vault/delta_real_collateral/DeltaRealBorrowAndDeltaRealCollateralData.sol";
import {DepositWithdrawData} from "src/structs/data/vault/common/DepositWithdrawData.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {Cases} from "src/structs/data/vault/common/Cases.sol";
import {DeltaRealBorrowAndDeltaRealCollateral} from
    "src/math/libraries/delta_future_collateral/DeltaRealBorrowAndDeltaRealCollateral.sol";
import {CommonBorrowCollateral} from "src/math/libraries/CommonBorrowCollateral.sol";
import {CasesOperator} from "src/math/libraries/CasesOperator.sol";
import {UMulDiv, SMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title DepositWithdraw
 * @notice This library contains function to calculate full state transition in underlying assets
 * for deposit, withdraw, deposit collateral and withdraw collateral vault operations.
 *
 * @dev These calculations are derived from the ltv protocol paper.
 */
library DepositWithdraw {
    using UMulDiv for uint256;
    using SMulDiv for int256;

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
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
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
