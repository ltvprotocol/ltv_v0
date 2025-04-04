// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../Structs.sol';
import '../../Constants.sol';
import '../../Cases.sol';
import '../../utils/MulDiv.sol';
import '../../State.sol';

library DeltaRealBorrowAndDeltaRealCollateral {
    using uMulDiv for uint256;
    using sMulDiv for int256;

    error DeltaRealBorrowAndDeltaRealCollateralUnexpectedError(
        ConvertedAssets convertedAssets,
        Prices prices,
        int256 deltaRealCollateral,
        int256 deltaRealBorrow
    );

    // needs to be rounded down in any case
    function calculateDividendByDeltaRealBorrowAndDeltaRealCollateral(
        Cases memory cases,
        Prices memory prices,
        ConvertedAssets memory convertedAssets,
        int256 deltaRealCollateral,
        int256 deltaRealBorrow,
        uint128 targetLTV
    )
        private
        pure
        returns (
            //bool isUp
            int256
        )
    {
        // dividend:
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

        int256 dividend = -int256(convertedAssets.borrow);
        dividend -= deltaRealBorrow;
        dividend -= int256(int8(cases.ceccb + cases.cecbc)) * (int256(convertedAssets.futureCollateral) - int256(convertedAssets.futureBorrow));
        dividend += int256(int8(cases.cecbc)) * int256(convertedAssets.userFutureRewardBorrow);

        // goes to dividend with plus sign, so need to round down
        dividend += int256(int8(cases.ceccb)) * convertedAssets.futureCollateral.mulDivDown(int256(prices.borrowSlippage), 10 ** 18);

        dividend += int256(int8(cases.cecbc)) * int256(convertedAssets.protocolFutureRewardBorrow);

        int256 dividendWithTargetLTV = int256(convertedAssets.collateral);
        dividendWithTargetLTV += deltaRealCollateral;
        dividendWithTargetLTV -= int256(int8(cases.ceccb)) * int256(convertedAssets.userFutureRewardCollateral);
        
        // goes to dividend with minus sign, so needs to be rounded up
        dividendWithTargetLTV -= int256(int8(cases.cecbc)) * convertedAssets.futureCollateral.mulDivUp(int256(prices.collateralSlippage), 10 ** 18);

        dividendWithTargetLTV -= int256(int8(cases.ceccb)) * int256(convertedAssets.protocolFutureRewardCollateral);
        
        // goes to dividend with plus sign, so needs to be rounded down
        dividend += dividendWithTargetLTV.mulDivDown(int128(targetLTV), int256(Constants.LTV_DIVIDER));

        return dividend;
    }

    // divider always positive
    function calculateDividerByDeltaRealBorrowAndDeltaRealCollateral(
        Cases memory cases,
        Prices memory prices,
        ConvertedAssets memory convertedAssets,
        uint128 targetLTV
    ) private pure returns (int256) {
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
        int256 DIVIDER = 10 ** 18;

        int256 divider = DIVIDER * int256(int8(cases.cna + cases.cmcb + cases.cmbc + cases.ceccb + cases.cecbc));

        // part 2
        if (convertedAssets.futureCollateral != 0) {
            int256 dividerDivFutureCollateral = int256(int8(cases.cecb + cases.cebc)) * int256(convertedAssets.futureBorrow);
            dividerDivFutureCollateral += int256(int8(cases.cebc)) * int256(convertedAssets.userFutureRewardBorrow);
            dividerDivFutureCollateral += int256(int8(cases.cebc)) * int256(convertedAssets.protocolFutureRewardBorrow);
            
            // goes to divider with sign plus, so need to round up
            if (cases.cecb != 0) {
                dividerDivFutureCollateral = dividerDivFutureCollateral.mulDivDown(DIVIDER, convertedAssets.futureCollateral);
            } else if (cases.cebc != 0) {
                dividerDivFutureCollateral = dividerDivFutureCollateral.mulDivUp(DIVIDER, convertedAssets.futureCollateral);
            }

            divider += dividerDivFutureCollateral;
        }

        // part 3

        int256 dividerBorrowSlippage = -int256(int8(cases.cmcb));
        dividerBorrowSlippage -= int256(int8(cases.ceccb));

        dividerBorrowSlippage = dividerBorrowSlippage * int256(prices.borrowSlippage);

        divider += dividerBorrowSlippage;

        // part 4-6

        // part 4
        int256 dividerTargetLTV = -DIVIDER;

        // part 5

        if (convertedAssets.futureCollateral != 0) {
            int256 dividerTargetLTVDivFutureCollateral = -int256(int8(cases.cecb)) * int256(convertedAssets.userFutureRewardCollateral);
            dividerTargetLTVDivFutureCollateral -= int256(int8(cases.cecb)) * int256(convertedAssets.protocolFutureRewardCollateral);
            // takes effect only in cecb case. Since it goes to divider with plus sign, needs to be rounded down
            dividerTargetLTVDivFutureCollateral = dividerTargetLTVDivFutureCollateral.mulDivDown(DIVIDER, int256(convertedAssets.futureCollateral));
            dividerTargetLTV += dividerTargetLTVDivFutureCollateral;
        }

        // part 6
        int256 dividerTargetLTVCollateralSlippage = int256(int8(cases.cmbc));
        dividerTargetLTVCollateralSlippage += int256(int8(cases.cecbc));

        dividerTargetLTVCollateralSlippage = dividerTargetLTVCollateralSlippage * int256(prices.collateralSlippage);
        dividerTargetLTV += dividerTargetLTVCollateralSlippage;

        if (cases.cmcb + cases.cebc + cases.ceccb != 0) {
            dividerTargetLTV = dividerTargetLTV.mulDivUp(int128(targetLTV), int256(Constants.LTV_DIVIDER));
        } else {
            dividerTargetLTV = dividerTargetLTV.mulDivDown(int128(targetLTV), int256(Constants.LTV_DIVIDER));
        }

        divider += dividerTargetLTV;

        return divider;
    }

    // These functions are used in Deposit/withdraw/mint/redeem. Since this math implies that deltaTotalAssets = deltaTotalShares, we don't have
    // HODLer conflict here. So the only conflict is between depositor/withdrawer and future executor. For future executor it's better to have smaller 
    // futureCollateral, so we need always round delta future collateral to the bottom
    // divider is always positive
    // cna - dividend is 0
    // cmcb, cebc, ceccb - deltaFutureCollateral is positive, so dividend is positive, dividend needs to be rounded down, divider needs to be rounded up
    // cmbc, cecb, cecbc - deltaFutureCollateral is negative, so dividend is negative, dividend needs to be rounded down, divider needs to be rounded down
    function calculateDeltaFutureCollateralByDeltaRealBorrowAndDeltaRealCollateral(
        Prices memory prices,
        ConvertedAssets memory convertedAssets,
        Cases memory cases,
        int256 deltaRealCollateral,
        int256 deltaRealBorrow,
        uint128 targetLTV
    ) external pure returns (int256, Cases memory) {
        int256 deltaFutureCollateral = 0;

        while (true) {
            int256 dividend = calculateDividendByDeltaRealBorrowAndDeltaRealCollateral(
                cases,
                prices,
                convertedAssets,
                deltaRealCollateral,
                deltaRealBorrow,
                targetLTV
            );

            int256 divider = calculateDividerByDeltaRealBorrowAndDeltaRealCollateral(cases, prices, convertedAssets, targetLTV);

            int256 DIVIDER = 10 ** 18;

            if (divider == 0) {
                if (cases.ncase >= 6) {
                    revert DeltaRealBorrowAndDeltaRealCollateralUnexpectedError(convertedAssets, prices, deltaRealCollateral, deltaRealBorrow);
                }
                cases = CasesOperator.generateCase(cases.ncase + 1);
                continue;
            }
            
            // round down since we need deltaFutureCollateral to be rounded down
            deltaFutureCollateral = dividend.mulDivDown(DIVIDER, divider);

            bool validity = CasesOperator.checkCaseDeltaFutureCollateral(cases, convertedAssets, deltaFutureCollateral);

            if (validity) {
                break;
            }

            if (cases.ncase == 6) {
                revert DeltaRealBorrowAndDeltaRealCollateralUnexpectedError(convertedAssets, prices, deltaRealCollateral, deltaRealBorrow);
            }

            cases = CasesOperator.generateCase(cases.ncase + 1);
        }

        return (deltaFutureCollateral, cases);
    }
}
