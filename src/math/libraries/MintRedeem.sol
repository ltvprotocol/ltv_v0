// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MintRedeemData} from "../../structs/data/vault/common/MintRedeemData.sol";
import {DeltaFuture} from "../../structs/state_transition/DeltaFuture.sol";
import {DeltaSharesAndDeltaRealCollateralData} from
    "../../structs/data/vault/delta_real_collateral/DeltaSharesAndDeltaRealCollateralData.sol";
import {DeltaSharesAndDeltaRealBorrowData} from
    "../../structs/data/vault/delta_real_borrow/DeltaSharesAndDeltaRealBorrowData.sol";
import {DeltaSharesAndDeltaRealCollateral} from
    "delta_future_collateral/DeltaSharesAndDeltaRealCollateral.sol";
import {DeltaSharesAndDeltaRealBorrow} from "delta_future_borrow/DeltaSharesAndDeltaRealBorrow.sol";
import {CommonBorrowCollateral} from "CommonBorrowCollateral.sol";
import {CasesOperator} from "CasesOperator.sol";
import {UMulDiv} from "MulDiv.sol";

/**
 * @title MintRedeem
 * @notice This library contains function to calculate full state transition in underlying assets
 * for mint, redeem and mint collateral, redeem collateral vault operations.
 *
 * @dev These calculations are derived from the ltv protocol paper.
 */
library MintRedeem {
    using UMulDiv for uint256;

    function calculateMintRedeem(MintRedeemData memory data)
        public
        pure
        returns (int256 assets, DeltaFuture memory deltaFuture)
    {
        deltaFuture.cases = CasesOperator.generateCase(0);

        // ∆shares = ∆userCollateral − ∆userBorrow
        // ∆userBorrow = ∆userCollateral - ∆shares

        // ∆userCollateral = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral
        // ∆userBorrow = ∆realBorrow + ∆futureBorrow + ∆userFutureRewardBorrow + ∆futurePaymentBorrow

        // ∆realBorrow = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral - ∆shares - ∆futureBorrow - ∆userFutureRewardBorrow - ∆futurePaymentBorrow
        if (data.isBorrow) {
            (deltaFuture.deltaFutureCollateral, deltaFuture.cases) = DeltaSharesAndDeltaRealCollateral
                .calculateDeltaFutureCollateralByDeltaSharesAndDeltaRealCollateral(
                DeltaSharesAndDeltaRealCollateralData({
                    targetLtvDividend: data.targetLtvDividend,
                    targetLtvDivider: data.targetLtvDivider,
                    borrow: data.borrow,
                    collateral: data.collateral,
                    protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                    protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                    deltaShares: data.deltaShares,
                    deltaRealCollateral: 0,
                    userFutureRewardCollateral: data.userFutureRewardCollateral,
                    futureCollateral: data.futureCollateral,
                    futureBorrow: data.futureBorrow,
                    collateralSlippage: data.collateralSlippage,
                    cases: deltaFuture.cases
                })
            );

            deltaFuture.deltaFutureBorrow = CommonBorrowCollateral.calculateDeltaFutureBorrowFromDeltaFutureCollateral(
                deltaFuture.cases, data.futureCollateral, data.futureBorrow, deltaFuture.deltaFutureCollateral
            );
        } else {
            (deltaFuture.deltaFutureBorrow, deltaFuture.cases) = DeltaSharesAndDeltaRealBorrow
                .calculateDeltaFutureBorrowByDeltaSharesAndDeltaRealBorrow(
                DeltaSharesAndDeltaRealBorrowData({
                    targetLtvDividend: data.targetLtvDividend,
                    targetLtvDivider: data.targetLtvDivider,
                    borrow: data.borrow,
                    collateral: data.collateral,
                    protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                    protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                    deltaShares: data.deltaShares,
                    deltaRealBorrow: 0,
                    userFutureRewardBorrow: data.userFutureRewardBorrow,
                    futureBorrow: data.futureBorrow,
                    futureCollateral: data.futureCollateral,
                    borrowSlippage: data.borrowSlippage,
                    cases: deltaFuture.cases
                })
            );

            deltaFuture.deltaFutureCollateral = CommonBorrowCollateral
                .calculateDeltaFutureCollateralFromDeltaFutureBorrow(
                deltaFuture.cases, data.futureCollateral, data.futureBorrow, deltaFuture.deltaFutureBorrow
            );
        }

        deltaFuture.deltaUserFutureRewardCollateral = CommonBorrowCollateral.calculateDeltaUserFutureRewardCollateral(
            deltaFuture.cases, data.futureCollateral, data.userFutureRewardCollateral, deltaFuture.deltaFutureCollateral
        );

        deltaFuture.deltaProtocolFutureRewardCollateral = CommonBorrowCollateral
            .calculateDeltaProtocolFutureRewardCollateral(
            deltaFuture.cases,
            data.futureCollateral,
            data.protocolFutureRewardCollateral,
            deltaFuture.deltaFutureCollateral
        );

        deltaFuture.deltaFuturePaymentCollateral = CommonBorrowCollateral.calculateDeltaFuturePaymentCollateral(
            deltaFuture.cases, data.futureCollateral, deltaFuture.deltaFutureCollateral, data.collateralSlippage
        );

        deltaFuture.deltaUserFutureRewardBorrow = CommonBorrowCollateral.calculateDeltaUserFutureRewardBorrow(
            deltaFuture.cases, data.futureBorrow, data.userFutureRewardBorrow, deltaFuture.deltaFutureBorrow
        );

        deltaFuture.deltaProtocolFutureRewardBorrow = CommonBorrowCollateral.calculateDeltaProtocolFutureRewardBorrow(
            deltaFuture.cases, data.futureBorrow, data.protocolFutureRewardBorrow, deltaFuture.deltaFutureBorrow
        );

        deltaFuture.deltaFuturePaymentBorrow = CommonBorrowCollateral.calculateDeltaFuturePaymentBorrow(
            deltaFuture.cases, data.futureBorrow, deltaFuture.deltaFutureBorrow, data.borrowSlippage
        );

        assets = deltaFuture.deltaFutureCollateral + deltaFuture.deltaUserFutureRewardCollateral
            + deltaFuture.deltaFuturePaymentCollateral - data.deltaShares - deltaFuture.deltaFutureBorrow
            - deltaFuture.deltaUserFutureRewardBorrow - deltaFuture.deltaFuturePaymentBorrow;

        assets = data.isBorrow ? assets : -assets;
    }
}
