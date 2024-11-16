// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./Structs.sol";
import "./Constants.sol";
import "./Cases.sol";

abstract contract RealBorrowAndRealCollateral {

    function calculateDividentRealBorrowAndRealCollateral(
        Cases memory cases,
        Prices memory prices, 
        ConvertedAssets memory convertedAssets,
        int256 deltaRealBorrow,
        int256 deltaRealCollateral
    ) public view returns (int256) {

        // divindent:
        //
        // -borrow
        // -ΔrealBorrow
        // -(ceccb + cecbc) x (futureCollateral - futureBorrow)
        // cecbc x userFutureRewardBorrow
        // ceccb x futureCollateral x borrowSlippage
        // cecbc x protocolFutureRewardBorrow
        // targetLTV x collateral
        // targetLTV x ΔrealCollateral
        // targetLTV x ceccb x - userFutureRewardCollateral
        // targetLTV x cecbc x -futureCollateral x collateralSlippage
        // targetLTV x ceccb x - protocolFutureRewardCollateral

        int256 divindent = -int256(convertedAssets.borrow);
        divindent -= deltaRealBorrow;
        divindent -= int256(int8(cases.ceccb + cases.cecbc)) * (int256(convertedAssets.futureCollateral) - int256(convertedAssets.futureBorrow));
        divindent += int256(int8(cases.cecbc)) * int256(convertedAssets.userFutureRewardBorrow);
        // TODO: fix borrowSlippage
        divindent += int256(int8(cases.ceccb)) * int256(convertedAssets.futureCollateral) * int256(prices.borrowSlippage);
        divindent += int256(int8(cases.cecbc)) * int256(convertedAssets.protocolFutureRewardBorrow);

        int256 divindentWithTargetLTV = int256(convertedAssets.collateral);
        divindentWithTargetLTV += deltaRealCollateral;
        divindentWithTargetLTV -= int256(int8(cases.ceccb)) * int256(convertedAssets.userFutureRewardCollateral);
        // TODO: fix collateralSlippage
        divindentWithTargetLTV -= int256(int8(cases.cecbc)) * int256(convertedAssets.futureCollateral) * int256(prices.collateralSlippage);
        divindentWithTargetLTV -= int256(int8(cases.ceccb)) * int256(convertedAssets.protocolFutureRewardCollateral);

        divindent += divindentWithTargetLTV * int256(Constants.TARGET_LTV) / int256(Constants.TARGET_LTV_DEVIDER);

        return divindent;
    }

    function calculateDividerRealBorrowAndRealCollateral(
        Cases memory cases,
        Prices memory prices, 
        ConvertedAssets memory convertedAssets
    ) public view returns (int256) {

        // divider
        //
        // (cna + cmcb + cmbc + ceccb + cecbc) x 1
        // (cecb + cebc) x futureBorrow/futureCollateral
        // cebc x userFutureRewardBorrow/futureCollateral
        // cmcb x - borrowSlippage
        // ceccb x - borrowSlippage
        // cebc x protocolFutureRewardBorrow/futureCollateral
        // - targetLTV x 1
        // - targetLTV x cecb x userFutureRewardCollateral/futureCollateral
        // targetLTV x cmbc x collateralSlippage
        // targetLTV x cecbc x collateralSlippage
        // - targetLTV x cecb x protocolFutureRewardCollateral/futureCollateral

        // translate into 6 parts

        // (cna + cmcb + cmbc + ceccb + cecbc) x 1

        // (cecb + cebc) x futureBorrow/futureCollateral
        // cebc x userFutureRewardBorrow/futureCollateral
        // cebc x protocolFutureRewardBorrow/futureCollateral

        // cmcb x - borrowSlippage
        // ceccb x - borrowSlippage

        // - targetLTV x 1

        // - targetLTV x cecb x userFutureRewardCollateral/futureCollateral
        // - targetLTV x cecb x protocolFutureRewardCollateral/futureCollateral

        // targetLTV x cmbc x collateralSlippage
        // targetLTV x cecbc x collateralSlippage


        // part 1
        int256 DEVIDER = 10**18;

        int256 divider = DEVIDER * int256(int8(cases.cna + cases.cmcb + cases.cmbc + cases.ceccb + cases.cecbc));

        // part 2
        int256 dividerDivFutureCollateral = int256(int8(cases.cecb + cases.cebc)) * int256(convertedAssets.futureBorrow);
        dividerDivFutureCollateral += int256(int8(cases.cebc)) * int256(convertedAssets.userFutureRewardBorrow);
        dividerDivFutureCollateral += int256(int8(cases.cebc)) * int256(convertedAssets.protocolFutureRewardBorrow);

        dividerDivFutureCollateral = dividerDivFutureCollateral * DEVIDER / int256(convertedAssets.futureCollateral);

        divider += dividerDivFutureCollateral;

        // part 3
        int256 dividerBorrowSlippage = -int256(int8(cases.cmcb));
        dividerBorrowSlippage -= int256(int8(cases.ceccb));

        dividerBorrowSlippage = int256(prices.borrowSlippage) * dividerBorrowSlippage / DEVIDER;

        divider += dividerBorrowSlippage;

        // part 4-6

        // part 4
        int256 dividerTargetLTV = -DEVIDER;

        // part 5

        int256 dividerTargetLTVDivFutureCollateral = -int256(int8(cases.cecb)) * int256(convertedAssets.userFutureRewardCollateral);
        dividerTargetLTVDivFutureCollateral -= int256(int8(cases.cecb)) * int256(convertedAssets.protocolFutureRewardCollateral);

        dividerTargetLTVDivFutureCollateral = dividerTargetLTVDivFutureCollateral * DEVIDER / int256(convertedAssets.futureCollateral);
        dividerTargetLTV += dividerTargetLTVDivFutureCollateral;

        // part 6
        int256 dividerTargetLTVCollateralSlippage = int256(int8(cases.cmbc));
        dividerTargetLTVCollateralSlippage += int256(int8(cases.cecbc));

        dividerTargetLTVCollateralSlippage = dividerTargetLTVCollateralSlippage * int256(prices.collateralSlippage) / DEVIDER;
        dividerTargetLTV += dividerTargetLTVCollateralSlippage;

        // end
        dividerTargetLTV = dividerTargetLTV * int256(Constants.TARGET_LTV) / int256(Constants.TARGET_LTV_DEVIDER);

        divider += dividerTargetLTV;

        return divider;

    }

    function calculateDeltaFutureCollateralRealBorrowAndRealCollateral(
        Prices memory prices, 
        ConvertedAssets memory convertedAssets,
        int256 deltaRealCollateral,
        int256 deltaShares
    ) public view returns (int256) {

        Cases memory cases = CasesOperator.generateCase(0);

        int256 deltaFutureCollateral = 0;

        while (true) {

            int256 divindent = calculateDividentRealBorrowAndRealCollateral(cases, prices, convertedAssets, deltaRealCollateral, deltaShares);

            int256 divider = calculateDividerRealBorrowAndRealCollateral(cases, prices, convertedAssets);

            int256 DEVIDER = 10**18;

            deltaFutureCollateral = divindent * DEVIDER / divider;

            bool validity = CasesOperator.checkCaseDeltaFutureCollateral(cases, convertedAssets, deltaFutureCollateral);

            if (validity) {
                break;
            }

            if (cases.ncase == 6) {
                // unexpected bihaviour
                return 0;
            }

            cases = CasesOperator.generateCase(cases.ncase + 1);
        }

        return deltaFutureCollateral;
    }
}