// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/structs/data/vault/Cases.sol";

library CasesOperator {
    function generateCase(uint8 ncase) internal pure returns (Cases memory) {
        return Cases({
            cmcb: (ncase == 0) ? 1 : 0,
            cmbc: (ncase == 1) ? 1 : 0,
            cecb: (ncase == 2) ? 1 : 0,
            cebc: (ncase == 3) ? 1 : 0,
            ceccb: (ncase == 4) ? 1 : 0,
            cecbc: (ncase == 5) ? 1 : 0,
            cna: (ncase == 6) ? 1 : 0,
            ncase: ncase
        });
    }

    function checkCaseDeltaFutureCollateral(Cases memory ncase, int256 futureCollateral, int256 deltaFutureCollateral)
        internal
        pure
        returns (bool)
    {
        // cna
        bool result = (ncase.cna == 1) && deltaFutureCollateral == 0;

        // cmcb
        result = result || ((ncase.cmcb == 1) && (futureCollateral <= 0) && (deltaFutureCollateral < 0));

        // cecb
        result = result
            || (
                (ncase.cecb == 1) && (futureCollateral + deltaFutureCollateral >= 0) && (futureCollateral > 0)
                    && (deltaFutureCollateral < 0)
            );

        // ceccb
        result = result
            || (
                (ncase.ceccb == 1) && (futureCollateral + deltaFutureCollateral < 0) && (futureCollateral > 0)
                    && (deltaFutureCollateral < 0)
            );

        // cmbc
        result = result || ((ncase.cmbc == 1) && (futureCollateral >= 0) && (deltaFutureCollateral > 0));

        // cebc
        result = result
            || (
                (ncase.cebc == 1) && (futureCollateral + deltaFutureCollateral <= 0) && (futureCollateral < 0)
                    && (deltaFutureCollateral > 0)
            );

        // cecbc
        result = result
            || (
                (ncase.cecbc == 1) && (futureCollateral + deltaFutureCollateral > 0) && (futureCollateral < 0)
                    && (deltaFutureCollateral > 0)
            );

        return result;
    }

    function checkCaseDeltaFutureBorrow(Cases memory ncase, int256 futureBorrow, int256 deltaFutureBorrow)
        internal
        pure
        returns (bool)
    {
        // cna
        bool result = (ncase.cna == 1) && deltaFutureBorrow == 0;

        // cmcb
        result = result || ((ncase.cmcb == 1) && (futureBorrow <= 0) && (deltaFutureBorrow < 0));

        // cecb
        result = result
            || (
                (ncase.cecb == 1) && (futureBorrow + deltaFutureBorrow >= 0) && (futureBorrow > 0)
                    && (deltaFutureBorrow < 0)
            );

        // ceccb
        result = result
            || (
                (ncase.ceccb == 1) && (futureBorrow + deltaFutureBorrow < 0) && (futureBorrow > 0)
                    && (deltaFutureBorrow < 0)
            );

        // cmbc
        result = result || ((ncase.cmbc == 1) && (futureBorrow >= 0) && (deltaFutureBorrow > 0));

        // cebc
        result = result
            || (
                (ncase.cebc == 1) && (futureBorrow + deltaFutureBorrow <= 0) && (futureBorrow < 0)
                    && (deltaFutureBorrow > 0)
            );

        // cecbc
        result = result
            || (
                (ncase.cecbc == 1) && (futureBorrow + deltaFutureBorrow > 0) && (futureBorrow < 0)
                    && (deltaFutureBorrow > 0)
            );

        return result;
    }
}
