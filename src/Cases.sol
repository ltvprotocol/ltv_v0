// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Structs.sol";

library CasesOperator {

    function generateCase(uint8 ncase) internal pure returns (Cases memory) {
        return Cases({
            cna: (ncase == 0) ? 1 : 0,
            cmcb: (ncase == 1) ? 1 : 0,
            cmbc: (ncase == 2) ? 1 : 0,
            cecb: (ncase == 3) ? 1 : 0,
            cebc: (ncase == 4) ? 1 : 0,
            ceccb: (ncase == 5) ? 1 : 0,
            cecbc: (ncase == 6) ? 1 : 0,
            ncase: ncase
        });
    }

    function checkCaseDeltaFutureCollateral(
        Cases memory ncase,
        ConvertedAssets memory convertedAssets,
        int256 deltaFutureCollateral
    ) internal pure returns (bool) {

        // cna
        bool result = (ncase.cna == 1) && deltaFutureCollateral == 0;

        // cmcb
        result = result || ((ncase.cmcb == 1) && (convertedAssets.futureCollateral <= 0) && (deltaFutureCollateral < 0));

        // cecb
        result = result || ((ncase.cecb == 1) && (convertedAssets.futureCollateral + deltaFutureCollateral >= 0) && (convertedAssets.futureCollateral > 0) && (deltaFutureCollateral < 0));

        // ceccb
        result = result || ((ncase.ceccb == 1) && (convertedAssets.futureCollateral + deltaFutureCollateral < 0) && (convertedAssets.futureCollateral > 0) && (deltaFutureCollateral < 0));

        // cmbc
        result = result || ((ncase.cmbc == 1) && (convertedAssets.futureCollateral >= 0) && (deltaFutureCollateral > 0));

        // cebc
        result = result || ((ncase.cebc == 1) && (convertedAssets.futureCollateral + deltaFutureCollateral <= 0) && (convertedAssets.futureCollateral < 0) && (deltaFutureCollateral > 0));

        // cecbc
        result = result || ((ncase.cecbc == 1) && (convertedAssets.futureCollateral + deltaFutureCollateral > 0) && (convertedAssets.futureCollateral < 0) && (deltaFutureCollateral > 0));

        return result;
    }

    function checkCaseDeltaFutureBorrow(
        Cases memory ncase,
        ConvertedAssets memory convertedAssets,
        int256 deltaFutureBorrow
    ) internal pure returns (bool) {

        // cna
        bool result = (ncase.cna == 1) && deltaFutureBorrow == 0;

        // cmcb
        result = result || ((ncase.cmcb == 1) && (convertedAssets.futureBorrow <= 0) && (deltaFutureBorrow < 0));

        // cecb
        result = result || ((ncase.cecb == 1) && (convertedAssets.futureBorrow + deltaFutureBorrow >= 0) && (convertedAssets.futureBorrow > 0) && (deltaFutureBorrow < 0));

        // ceccb
        result = result || ((ncase.ceccb == 1) && (convertedAssets.futureBorrow + deltaFutureBorrow < 0) && (convertedAssets.futureBorrow > 0) && (deltaFutureBorrow < 0));

        // cmbc
        result = result || ((ncase.cmbc == 1) && (convertedAssets.futureBorrow >= 0) && (deltaFutureBorrow > 0));

        // cebc
        result = result || ((ncase.cebc == 1) && (convertedAssets.futureBorrow + deltaFutureBorrow <= 0) && (convertedAssets.futureBorrow < 0) && (deltaFutureBorrow > 0));

        // cecbc
        result = result || ((ncase.cecbc == 1) && (convertedAssets.futureBorrow + deltaFutureBorrow > 0) && (convertedAssets.futureBorrow < 0) && (deltaFutureBorrow > 0));

        return result;
    }

}