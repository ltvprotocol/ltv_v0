// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../structs/data/vault/DeltaRealBorrowAndDeltaRealCollateralData.sol";
import "../../structs/data/vault/Cases.sol";
import "../../Constants.sol";
import "src/math/CasesOperator.sol";
import "../../utils/MulDiv.sol";
import "src/errors/IVaultErrors.sol";

library DeltaRealBorrowAndDeltaRealCollateral {
    using uMulDiv for uint256;
    using sMulDiv for int256;

    struct DividendData {
        Cases cases;
        int256 borrow;
        int256 deltaRealBorrow;
        int256 futureCollateral;
        int256 futureBorrow;
        int256 userFutureRewardBorrow;
        int256 userFutureRewardCollateral;
        uint256 borrowSlippage;
        uint256 collateralSlippage;
        int256 protocolFutureRewardBorrow;
        int256 protocolFutureRewardCollateral;
        int256 collateral;
        int256 deltaRealCollateral;
        uint16 targetLTVDividend;
        uint16 targetLTVDivider;
    }

    struct DividerData {
        Cases cases;
        int256 futureCollateral;
        int256 futureBorrow;
        uint256 collateralSlippage;
        uint256 borrowSlippage;
        int256 collateral;
        int256 protocolFutureRewardBorrow;
        int256 protocolFutureRewardCollateral;
        uint16 targetLTVDividend;
        uint16 targetLTVDivider;
        int256 userFutureRewardBorrow;
        int256 userFutureRewardCollateral;
    }

    // needs to be rounded down in any case
    function calculateDividendByDeltaRealBorrowAndDeltaRealCollateral(DividendData memory data)
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

        bool needToRoundUp = (data.cases.cmcb + data.cases.ceccb + data.cases.cebc == 0);

        int256 dividend = -int256(data.borrow);
        dividend -= data.deltaRealBorrow;
        dividend -= int256(int8(data.cases.ceccb + data.cases.cecbc))
            * (int256(data.futureCollateral) - int256(data.futureBorrow));
        dividend += int256(int8(data.cases.cecbc)) * int256(data.userFutureRewardBorrow);

        dividend += int256(int8(data.cases.ceccb))
            * data.futureCollateral.mulDiv(int256(data.borrowSlippage), 10 ** 18, needToRoundUp);

        dividend += int256(int8(data.cases.cecbc)) * int256(data.protocolFutureRewardBorrow);

        int256 dividendWithTargetLTV = int256(data.collateral);
        dividendWithTargetLTV += data.deltaRealCollateral;
        dividendWithTargetLTV -= int256(int8(data.cases.ceccb)) * int256(data.userFutureRewardCollateral);

        dividendWithTargetLTV += int256(int8(data.cases.cecbc))
            * (-data.futureCollateral).mulDiv(int256(data.collateralSlippage), 10 ** 18, needToRoundUp);

        dividendWithTargetLTV -= int256(int8(data.cases.ceccb)) * int256(data.protocolFutureRewardCollateral);

        dividend += dividendWithTargetLTV.mulDiv(
            int256(uint256(data.targetLTVDividend)), int256(uint256(data.targetLTVDivider)), needToRoundUp
        );

        return dividend;
    }

    // divider always positive
    function calculateDividerByDeltaRealBorrowAndDeltaRealCollateral(DividerData memory data)
        private
        pure
        returns (int256)
    {
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
        bool needToRoundUp = (data.cases.cebc + data.cases.cecb != 0);
        int256 DIVIDER = 10 ** 18;

        int256 divider = DIVIDER
            * int256(int8(data.cases.cna + data.cases.cmcb + data.cases.cmbc + data.cases.ceccb + data.cases.cecbc));

        // part 2
        if (data.futureCollateral != 0) {
            int256 dividerDivFutureCollateral =
                int256(int8(data.cases.cecb + data.cases.cebc)) * int256(data.futureBorrow);
            dividerDivFutureCollateral += int256(int8(data.cases.cebc)) * int256(data.userFutureRewardBorrow);
            dividerDivFutureCollateral += int256(int8(data.cases.cebc)) * int256(data.protocolFutureRewardBorrow);

            dividerDivFutureCollateral =
                dividerDivFutureCollateral.mulDiv(DIVIDER, data.futureCollateral, needToRoundUp);

            divider += dividerDivFutureCollateral;
        }

        // part 3

        int256 dividerBorrowSlippage = -int256(int8(data.cases.cmcb));
        dividerBorrowSlippage -= int256(int8(data.cases.ceccb));

        dividerBorrowSlippage = dividerBorrowSlippage * int256(data.borrowSlippage);

        divider += dividerBorrowSlippage;

        // part 4-6

        // part 4
        int256 dividerTargetLTV = -DIVIDER;

        // part 5

        if (data.futureCollateral != 0) {
            int256 dividerTargetLTVDivFutureCollateral =
                -int256(int8(data.cases.cecb)) * int256(data.userFutureRewardCollateral);
            dividerTargetLTVDivFutureCollateral -=
                int256(int8(data.cases.cecb)) * int256(data.protocolFutureRewardCollateral);
            // takes effect only in cecb case. Since it goes to divider with plus sign, needs to be rounded down
            dividerTargetLTVDivFutureCollateral =
                dividerTargetLTVDivFutureCollateral.mulDiv(DIVIDER, int256(data.futureCollateral), needToRoundUp);
            dividerTargetLTV += dividerTargetLTVDivFutureCollateral;
        }

        // part 6
        int256 dividerTargetLTVCollateralSlippage = int256(int8(data.cases.cmbc));
        dividerTargetLTVCollateralSlippage += int256(int8(data.cases.cecbc));

        dividerTargetLTVCollateralSlippage = dividerTargetLTVCollateralSlippage * int256(data.collateralSlippage);
        dividerTargetLTV += dividerTargetLTVCollateralSlippage;

        dividerTargetLTV = dividerTargetLTV.mulDiv(
            int256(uint256(data.targetLTVDividend)), int256(uint256(data.targetLTVDivider)), needToRoundUp
        );

        divider += dividerTargetLTV;

        return divider;
    }

    /**
     *
     * For every single case we need to round deltaFutureCollateral in the way to help case to
     * be valid
     * cmcb: For this case deltaFutureCollateral < 0. To help it be indeed negative we need to round deltaFutureCollateral to the bottom
     * cebc: deltaFutureCollateral > 0, but deltaFutureCollateral < -futureCollateral. So round it down. In case
     * deltaFutureColateral == 0 this case will be interpretted as cna
     * cecbc: deltaFutureCollateral > 0 and deltaFutureCollateral > -futureCollateral. So round it up
     * cecb: deltaFutureCollateral < 0, but deltaFutureCollateral > -futureCollateral. So round it up. In case deltaFutureCollateral == 0 this case will be interpretted as cna
     * cmbc: deltaFutureCollateral > 0, so round it up.
     * ceccb: deltaFutureCollateral < 0 and deltaFutureCollateral < -futureCollateral. So round it down
     *
     *
     * Dividend and divider roundings:
     * cmcb, ceccb - deltaFutureCollateral < 0 and rounding down. dividend < 0, divider > 0, round dividend down, round divider down
     * cebc - deltaFutureCollateral > 0 and rounding down. So dividend > 0, divider > 0, round dividend down, round divider up
     * cmbc, cecbc - deltaFutureCollateral > 0 and rounding up. So dividend > 0, divider > 0, round dividend up, round divider down
     * cecb - deltaFutureCollateral < 0 and rounding up. So dividend < 0, divider > 0, round dividend up, round divider up
     *
     * ROUNDING DIVIDEND/DIVIDER:
     * cecb, cecbc, cmbc - round up
     * cmcb, cebc, ceccb - round down
     *
     * ROUNDING DIVIDER:
     * cmcb, ceccb, cmbc, cecbc - rounding down
     * cebc, cecb - rounding up
     *
     * ROUDNING DIVIDEND:
     * cmcb, ceccb, cebc - rounding down
     * cmcb, cecbc, cecb - rounding up
     */
    function calculateDeltaFutureCollateralByDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralData memory data
    ) external pure returns (int256, Cases memory) {
        int256 deltaFutureCollateral = 0;
        while (true) {
            int256 dividend = calculateDividendByDeltaRealBorrowAndDeltaRealCollateral(
                DividendData({
                    cases: data.cases,
                    borrow: data.borrow,
                    deltaRealBorrow: data.deltaRealBorrow,
                    futureCollateral: data.futureCollateral,
                    futureBorrow: data.futureBorrow,
                    userFutureRewardBorrow: data.userFutureRewardBorrow,
                    userFutureRewardCollateral: data.userFutureRewardCollateral,
                    borrowSlippage: data.borrowSlippage,
                    collateralSlippage: data.collateralSlippage,
                    protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                    protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                    collateral: data.collateral,
                    deltaRealCollateral: data.deltaRealCollateral,
                    targetLTVDividend: data.targetLTVDividend,
                    targetLTVDivider: data.targetLTVDivider
                })
            );

            if (dividend == 0 && data.cases.cecb + data.cases.cebc != 0) {
                return (0, CasesOperator.generateCase(6));
            }

            int256 divider = calculateDividerByDeltaRealBorrowAndDeltaRealCollateral(
                DividerData({
                    cases: data.cases,
                    futureCollateral: data.futureCollateral,
                    futureBorrow: data.futureBorrow,
                    collateralSlippage: data.collateralSlippage,
                    borrowSlippage: data.borrowSlippage,
                    collateral: data.collateral,
                    protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                    protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                    targetLTVDividend: data.targetLTVDividend,
                    targetLTVDivider: data.targetLTVDivider,
                    userFutureRewardBorrow: data.userFutureRewardBorrow,
                    userFutureRewardCollateral: data.userFutureRewardCollateral
                })
            );

            int256 DIVIDER = 10 ** 18;

            if (divider == 0) {
                if (data.cases.ncase >= 5) {
                    revert IVaultErrors.DeltaRealBorrowAndDeltaRealCollateralUnexpectedError(data);
                }
                data.cases = CasesOperator.generateCase(data.cases.ncase + 1);
                continue;
            }

            bool needToRoundUp = (data.cases.cecb + data.cases.cecbc + data.cases.cmbc != 0);

            deltaFutureCollateral = dividend.mulDiv(DIVIDER, divider, needToRoundUp);

            bool validity =
                CasesOperator.checkCaseDeltaFutureCollateral(data.cases, data.futureCollateral, deltaFutureCollateral);

            if (validity) {
                break;
            }

            if (data.cases.ncase == 5) {
                revert IVaultErrors.DeltaRealBorrowAndDeltaRealCollateralUnexpectedError(data);
            }

            data.cases = CasesOperator.generateCase(data.cases.ncase + 1);
        }

        return (deltaFutureCollateral, data.cases);
    }
}
