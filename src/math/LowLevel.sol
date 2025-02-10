// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "../Cases.sol";
import "../utils/MulDiv.sol";
import "./CommonBorrowCollateral.sol";
import "./deltaFutureCollateral/DeltaSharesAndDeltaRealCollateral.sol";

abstract contract LowLevel is State, CommonBorrowCollateral {

    function calculateLowLevel(int256 borrow, int256 collateral) internal view returns (int256 shares) {

        int256 deltaRealBorrow = borrow * int256(getPriceBorrowOracle() / Constants.ORACLE_DIVIDER);
        int256 deltaRealCollateral = collateral * int256(getPriceBorrowOracle() / Constants.ORACLE_DIVIDER);

        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        uint8[3] memory possibleCases = [0, 2, 5];

        uint256 caseIndex = 0;

        while (true) {

            Cases memory cases = CasesOperator.generateCase(possibleCases[caseIndex]);

            DeltaFuture memory deltaFuture;

            deltaFuture.deltaFutureCollateral = -convertedAssets.futureCollateral;

            deltaFuture.deltaFutureBorrow = -convertedAssets.futureBorrow;

            deltaFuture.deltaUserFutureRewardCollateral = calculateDeltaUserFutureRewardCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);

            // TODO: calculate deltaFuture.deltaProtocolFutureRewardCollateral

            deltaFuture.deltaFuturePaymentCollateral = calculateDeltaFuturePaymentCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);

            deltaFuture.deltaUserFutureRewardBorrow = calculateDeltaUserFutureRewardBorrow(cases, convertedAssets, deltaFuture.deltaFutureBorrow);

            // TODO: calculate deltaFuture.deltaProtocolFutureRewardBorrow

            deltaFuture.deltaFuturePaymentBorrow = calculateDeltaFuturePaymentBorrow(cases, convertedAssets, deltaFuture.deltaFutureBorrow);

            int256 deltaCollateral = deltaRealCollateral 
                + deltaFuture.deltaFutureCollateral
                + deltaFuture.deltaUserFutureRewardCollateral
                + deltaFuture.deltaFuturePaymentCollateral;
                // + deltaFuture.deltaProtocolFutureRewardCollateral

            int256 deltaBorrow = deltaRealBorrow
                + deltaFuture.deltaFutureBorrow
                + deltaFuture.deltaUserFutureRewardBorrow
                + deltaFuture.deltaFuturePaymentBorrow;
                // + deltaFuture.deltaProtocolFutureRewardBorrow

            bool validityTargetLTV = (convertedAssets.collateral + deltaCollateral) * int256(Constants.TARGET_LTV) == int256(Constants.TARGET_LTV_DIVIDER) * (convertedAssets.borrow + deltaBorrow);

            // TODO: mb think about delta here, not exact ==

            // ∆shares = ∆userCollateral − ∆userBorrow
            // ∆userCollateral = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral
            // ∆userBorrow = ∆realBorrow + ∆futureBorrow + ∆userFutureRewardBorrow + ∆futurePaymentBorrow

            shares = deltaRealCollateral 
                + deltaFuture.deltaFutureCollateral
                + deltaFuture.deltaUserFutureRewardCollateral
                + deltaFuture.deltaFuturePaymentCollateral
                - deltaRealBorrow
                - deltaFuture.deltaFutureBorrow
                - deltaFuture.deltaUserFutureRewardBorrow
                - deltaFuture.deltaFuturePaymentBorrow;

            bool validityCollateral = CasesOperator.checkCaseDeltaFutureCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);
            bool validityBorrow = CasesOperator.checkCaseDeltaFutureBorrow(cases, convertedAssets, deltaFuture.deltaFutureBorrow);

            if (validityCollateral && validityBorrow && validityTargetLTV) {
                break;
            }

            if (cases.ncase == 3) {
                // non correct borrow and collateral
                return 0;
            }

            cases = CasesOperator.generateCase(cases.ncase + 1);
        }
        
        return shares;
    }
}
