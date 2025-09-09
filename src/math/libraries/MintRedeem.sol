// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MintRedeemData} from "src/structs/data/vault/MintRedeemData.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {Cases} from "src/structs/data/vault/Cases.sol";
import {DeltaSharesAndDeltaRealCollateralData} from "src/structs/data/vault/DeltaSharesAndDeltaRealCollateralData.sol";
import {DeltaSharesAndDeltaRealBorrowData} from "src/structs/data/vault/DeltaSharesAndDeltaRealBorrowData.sol";
import {DeltaSharesAndDeltaRealCollateral} from
    "src/math/libraries/delta_future_collateral/DeltaSharesAndDeltaRealCollateral.sol";
import {DeltaSharesAndDeltaRealBorrow} from "src/math/libraries/delta_future_borrow/DeltaSharesAndDeltaRealBorrow.sol";
import {CommonBorrowCollateral} from "src/math/libraries/CommonBorrowCollateral.sol";
import {CasesOperator} from "src/math/libraries/CasesOperator.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

/**
 * @title MintRedeem
 * @notice This library contains function to calculate full state transition in underlying assets
 * for mint, redeem and mint collateral, redeem collateral vault operations.
 *
 * @dev These calculations are derived from the ltv protocol paper.
 */
library MintRedeem {
    using uMulDiv for uint256;

    function calculateMintRedeem(MintRedeemData memory data)
        public
        pure
        returns (int256 assets, DeltaFuture memory deltaFuture)
    {
        Cases memory cases = CasesOperator.generateCase(0);

        // ∆shares = ∆userCollateral − ∆userBorrow
        // ∆userBorrow = ∆userCollateral - ∆shares

        // ∆userCollateral = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral
        // ∆userBorrow = ∆realBorrow + ∆futureBorrow + ∆userFutureRewardBorrow + ∆futurePaymentBorrow

        // ∆realBorrow = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral - ∆shares - ∆futureBorrow - ∆userFutureRewardBorrow - ∆futurePaymentBorrow
        if (data.isBorrow) {
            (deltaFuture.deltaFutureCollateral, cases) = DeltaSharesAndDeltaRealCollateral
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
                    collateralSlippage: data.collateralSlippage,
                    cases: cases
                })
            );

            deltaFuture.deltaFutureBorrow = CommonBorrowCollateral.calculateDeltaFutureBorrowFromDeltaFutureCollateral(
                cases, data.futureCollateral, data.futureBorrow, deltaFuture.deltaFutureCollateral
            );
        } else {
            (deltaFuture.deltaFutureBorrow, cases) = DeltaSharesAndDeltaRealBorrow
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
                    borrowSlippage: data.borrowSlippage,
                    cases: cases
                })
            );

            deltaFuture.deltaFutureCollateral = CommonBorrowCollateral
                .calculateDeltaFutureCollateralFromDeltaFutureBorrow(
                cases, data.futureCollateral, data.futureBorrow, deltaFuture.deltaFutureBorrow
            );
        }

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

        assets = deltaFuture.deltaFutureCollateral + deltaFuture.deltaUserFutureRewardCollateral
            + deltaFuture.deltaFuturePaymentCollateral - data.deltaShares - deltaFuture.deltaFutureBorrow
            - deltaFuture.deltaUserFutureRewardBorrow - deltaFuture.deltaFuturePaymentBorrow;

        assets = data.isBorrow ? assets : -assets;
    }
}
