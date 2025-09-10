// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {IVaultErrors} from "src/errors/IVaultErrors.sol";
import {Cases} from "src/structs/data/vault/common/Cases.sol";
import {DeltaRealBorrowAndDeltaRealCollateralData} from
    "src/structs/data/vault/delta_real_collateral/DeltaRealBorrowAndDeltaRealCollateralData.sol";
import {DeltaRealBorrowAndDeltaRealCollateralDividendData} from
    "src/structs/data/vault/delta_real_collateral/DeltaRealBorrowAndDeltaRealCollateralDividendData.sol";
import {DeltaRealBorrowAndDeltaRealCollateralDividerData} from
    "src/structs/data/vault/delta_real_collateral/DeltaRealBorrowAndDeltaRealCollateralDividerData.sol";
import {CasesOperator} from "src/math/libraries/CasesOperator.sol";
import {UMulDiv, SMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title DeltaRealBorrowAndDeltaRealCollateral
 * @notice This library contains functions to calculate deltaFutureCollateral by deltaRealBorrow and deltaRealCollateral.
 *
 * @dev These calculations are derived from the ltv protocol paper. This function calculates deltaFutureCollateral
 * when deltaRealBorrow and deltaRealCollateral are provided. It goes through all the possible cases to find the valid deltaFutureCollateral.
 * Depending on the current auction direction only some cases are possible. Since you can't execute collateral to borrow auction when
 * borrow to collateral auction is in progress, and vice versa.
 *
 */
library DeltaRealBorrowAndDeltaRealCollateral {
    using UMulDiv for uint256;
    using SMulDiv for int256;

    // needs to be rounded down in any case
    function calculateDividendByDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralDividendData memory data,
        bool needToRoundUp
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
        // targetLtv x collateral
        // targetLtv x ΔrealCollateral
        // targetLtv x ceccb x - userFutureRewardCollateral
        // targetLtv x cecbc x -futureCollateral x collateralSlippage
        // targetLtv x ceccb x - protocolFutureRewardCollateral

        int256 dividend = -int256(data.borrow);
        dividend -= data.deltaRealBorrow;
        dividend -= int256(int8(data.cases.ceccb + data.cases.cecbc))
            * (int256(data.futureCollateral) - int256(data.futureBorrow));
        dividend += int256(int8(data.cases.cecbc)) * int256(data.userFutureRewardBorrow);

        dividend += int256(int8(data.cases.ceccb))
            * data.futureCollateral.mulDiv(int256(data.borrowSlippage), 10 ** 18, needToRoundUp);

        dividend += int256(int8(data.cases.cecbc)) * int256(data.protocolFutureRewardBorrow);

        int256 dividendWithtargetLtv = int256(data.collateral);
        dividendWithtargetLtv += data.deltaRealCollateral;
        dividendWithtargetLtv -= int256(int8(data.cases.ceccb)) * int256(data.userFutureRewardCollateral);

        dividendWithtargetLtv += int256(int8(data.cases.cecbc))
            * (-data.futureCollateral).mulDiv(int256(data.collateralSlippage), 10 ** 18, needToRoundUp);

        dividendWithtargetLtv -= int256(int8(data.cases.ceccb)) * int256(data.protocolFutureRewardCollateral);

        dividend += dividendWithtargetLtv.mulDiv(
            int256(uint256(data.targetLtvDividend)), int256(uint256(data.targetLtvDivider)), needToRoundUp
        );

        return dividend;
    }

    // divider always positive
    function calculateDividerByDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralDividerData memory data,
        bool needToRoundUp
    ) private pure returns (int256) {
        // divider
        //
        // (cna + cmcb + cmbc + ceccb + cecbc) x 1
        // (cecb + cebc) x futureBorrow/futureCollateral
        // cebc x userFutureRewardBorrow/futureCollateral
        // cmcb x - borrowSlippage
        // ceccb x - borrowSlippage
        // cebc x protocolFutureRewardBorrow/futureCollateral
        // - targetLtv x 1
        // - targetLtv x cecb x userFutureRewardCollateral/futureCollateral
        // targetLtv x cmbc x collateralSlippage
        // targetLtv x cecbc x collateralSlippage
        // - targetLtv x cecb x protocolFutureRewardCollateral/futureCollateral

        // translate into 6 parts

        // (cna + cmcb + cmbc + ceccb + cecbc) x 1

        // (cecb + cebc) x futureBorrow/futureCollateral
        // cebc x userFutureRewardBorrow/futureCollateral
        // cebc x protocolFutureRewardBorrow/futureCollateral

        // cmcb x - borrowSlippage
        // ceccb x - borrowSlippage

        // - targetLtv x 1

        // - targetLtv x cecb x userFutureRewardCollateral/futureCollateral
        // - targetLtv x cecb x protocolFutureRewardCollateral/futureCollateral

        // targetLtv x cmbc x collateralSlippage
        // targetLtv x cecbc x collateralSlippage

        // part 1

        int256 divider = Constants.DIVIDER_PRECISION
            * int256(int8(data.cases.cna + data.cases.cmcb + data.cases.cmbc + data.cases.ceccb + data.cases.cecbc));

        // part 2
        if (data.futureCollateral != 0) {
            int256 dividerDivFutureCollateral =
                int256(int8(data.cases.cecb + data.cases.cebc)) * int256(data.futureBorrow);
            dividerDivFutureCollateral += int256(int8(data.cases.cebc)) * int256(data.userFutureRewardBorrow);
            dividerDivFutureCollateral += int256(int8(data.cases.cebc)) * int256(data.protocolFutureRewardBorrow);

            dividerDivFutureCollateral =
                dividerDivFutureCollateral.mulDiv(Constants.DIVIDER_PRECISION, data.futureCollateral, needToRoundUp);

            divider += dividerDivFutureCollateral;
        }

        // part 3

        int256 dividerBorrowSlippage = -int256(int8(data.cases.cmcb));
        dividerBorrowSlippage -= int256(int8(data.cases.ceccb));

        dividerBorrowSlippage = dividerBorrowSlippage * int256(data.borrowSlippage);

        divider += dividerBorrowSlippage;

        // part 4-6

        // part 4
        int256 dividertargetLtv = -Constants.DIVIDER_PRECISION;

        // part 5

        if (data.futureCollateral != 0) {
            int256 dividertargetLtvDivFutureCollateral =
                -int256(int8(data.cases.cecb)) * int256(data.userFutureRewardCollateral);
            dividertargetLtvDivFutureCollateral -=
                int256(int8(data.cases.cecb)) * int256(data.protocolFutureRewardCollateral);
            // takes effect only in cecb case. Since it goes to divider with plus sign, needs to be rounded down
            dividertargetLtvDivFutureCollateral = dividertargetLtvDivFutureCollateral.mulDiv(
                Constants.DIVIDER_PRECISION, int256(data.futureCollateral), needToRoundUp
            );
            dividertargetLtv += dividertargetLtvDivFutureCollateral;
        }

        // part 6
        int256 dividertargetLtvCollateralSlippage = int256(int8(data.cases.cmbc));
        dividertargetLtvCollateralSlippage += int256(int8(data.cases.cecbc));

        dividertargetLtvCollateralSlippage = dividertargetLtvCollateralSlippage * int256(data.collateralSlippage);
        dividertargetLtv += dividertargetLtvCollateralSlippage;

        dividertargetLtv = dividertargetLtv.mulDiv(
            int256(uint256(data.targetLtvDividend)), int256(uint256(data.targetLtvDivider)), needToRoundUp
        );

        divider += dividertargetLtv;

        return divider;
    }

    function calculateSingleCaseDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralData memory data,
        bool needToRoundUpDividend,
        bool needToRoundUpDivider
    ) internal pure returns (int256, bool) {
        int256 deltaFutureCollateral;

        int256 dividend = calculateDividendByDeltaRealBorrowAndDeltaRealCollateral(
            DeltaRealBorrowAndDeltaRealCollateralDividendData({
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
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider
            }),
            needToRoundUpDividend
        );

        int256 divider = calculateDividerByDeltaRealBorrowAndDeltaRealCollateral(
            DeltaRealBorrowAndDeltaRealCollateralDividerData({
                cases: data.cases,
                futureCollateral: data.futureCollateral,
                futureBorrow: data.futureBorrow,
                collateralSlippage: data.collateralSlippage,
                borrowSlippage: data.borrowSlippage,
                collateral: data.collateral,
                protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                userFutureRewardBorrow: data.userFutureRewardBorrow,
                userFutureRewardCollateral: data.userFutureRewardCollateral
            }),
            needToRoundUpDivider
        );

        if (divider == 0) {
            return (0, false);
        }

        bool needToRoundUp = needToRoundUpDividend;

        deltaFutureCollateral = dividend.mulDiv(Constants.DIVIDER_PRECISION, divider, needToRoundUp);

        return (deltaFutureCollateral, true);
    }

    function calculateSingleCaseCacheDividendDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralData memory data,
        bool needToRoundUpDividend,
        bool needToRoundUpDivider,
        int256 dividend
    ) internal pure returns (int256, bool) {
        int256 deltaFutureCollateral;

        int256 divider = calculateDividerByDeltaRealBorrowAndDeltaRealCollateral(
            DeltaRealBorrowAndDeltaRealCollateralDividerData({
                cases: data.cases,
                futureCollateral: data.futureCollateral,
                futureBorrow: data.futureBorrow,
                collateralSlippage: data.collateralSlippage,
                borrowSlippage: data.borrowSlippage,
                collateral: data.collateral,
                protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                userFutureRewardBorrow: data.userFutureRewardBorrow,
                userFutureRewardCollateral: data.userFutureRewardCollateral
            }),
            needToRoundUpDivider
        );

        if (divider == 0) {
            return (0, false);
        }

        bool needToRoundUp = needToRoundUpDividend;

        deltaFutureCollateral = dividend.mulDiv(Constants.DIVIDER_PRECISION, divider, needToRoundUp);

        return (deltaFutureCollateral, true);
    }

    function calculateCaseCmcbDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralData memory data,
        int256 cacheDividend,
        bool cache
    ) internal pure returns (int256, Cases memory, bool) {
        data.cases = CasesOperator.generateCase(0); // cmcb case

        int256 deltaFutureCollateral;
        bool success;

        if (cache) {
            (deltaFutureCollateral, success) =
                calculateSingleCaseCacheDividendDeltaRealBorrowAndDeltaRealCollateral(data, false, false, cacheDividend);
        } else {
            (deltaFutureCollateral, success) =
                calculateSingleCaseDeltaRealBorrowAndDeltaRealCollateral(data, false, false);
        }
        return (deltaFutureCollateral, data.cases, success);
    }

    function calculateCaseCmbcDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralData memory data,
        int256 cacheDividend,
        bool cache
    ) internal pure returns (int256, Cases memory, bool) {
        data.cases = CasesOperator.generateCase(1); // cmbc case

        int256 deltaFutureCollateral;
        bool success;

        if (cache) {
            (deltaFutureCollateral, success) =
                calculateSingleCaseCacheDividendDeltaRealBorrowAndDeltaRealCollateral(data, true, false, cacheDividend);
        } else {
            (deltaFutureCollateral, success) =
                calculateSingleCaseDeltaRealBorrowAndDeltaRealCollateral(data, true, false);
        }
        return (deltaFutureCollateral, data.cases, success);
    }

    function calculateCaseCecbDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralData memory data,
        int256 cacheDividend
    ) internal pure returns (int256, Cases memory, bool) {
        data.cases = CasesOperator.generateCase(2); // cecb case
        (int256 deltaFutureCollateral, bool success) =
            calculateSingleCaseCacheDividendDeltaRealBorrowAndDeltaRealCollateral(data, true, true, cacheDividend);
        return (deltaFutureCollateral, data.cases, success);
    }

    function calculateCaseCebcDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralData memory data,
        int256 cacheDividend
    ) internal pure returns (int256, Cases memory, bool) {
        data.cases = CasesOperator.generateCase(3); // cebc case
        (int256 deltaFutureCollateral, bool success) =
            calculateSingleCaseCacheDividendDeltaRealBorrowAndDeltaRealCollateral(data, false, true, cacheDividend);
        return (deltaFutureCollateral, data.cases, success);
    }

    function calculateCaseCeccbDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralData memory data
    ) internal pure returns (int256, Cases memory, bool) {
        data.cases = CasesOperator.generateCase(4); // ceccb case
        (int256 deltaFutureCollateral, bool success) =
            calculateSingleCaseDeltaRealBorrowAndDeltaRealCollateral(data, false, false);
        return (deltaFutureCollateral, data.cases, success);
    }

    function calculateCaseCecbcDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralData memory data
    ) internal pure returns (int256, Cases memory, bool) {
        data.cases = CasesOperator.generateCase(5); // cecbc case
        (int256 deltaFutureCollateral, bool success) =
            calculateSingleCaseDeltaRealBorrowAndDeltaRealCollateral(data, true, false);
        return (deltaFutureCollateral, data.cases, success);
    }

    function neutralDividendDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralData memory data,
        bool needToRoundUpDividend
    ) internal pure returns (int256 dividend) {
        data.cases = CasesOperator.generateCase(6); // cna case - neutral case

        dividend = calculateDividendByDeltaRealBorrowAndDeltaRealCollateral(
            DeltaRealBorrowAndDeltaRealCollateralDividendData({
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
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider
            }),
            needToRoundUpDividend
        );
    }

    function positiveFutureCollateralBranchDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralData memory data
    ) internal pure returns (int256, Cases memory) {
        int256 deltaFutureCollateral;
        Cases memory cases;
        bool success;

        int256 cacheDividend = neutralDividendDeltaRealBorrowAndDeltaRealCollateral(data, true);

        (deltaFutureCollateral, cases, success) =
            calculateCaseCmbcDeltaRealBorrowAndDeltaRealCollateral(data, cacheDividend, true);

        if (deltaFutureCollateral > 0 && success) {
            return (deltaFutureCollateral, cases);
        }

        if (deltaFutureCollateral == 0 && success) {
            cases = CasesOperator.generateCase(6); // cna
            return (0, cases);
        }

        (deltaFutureCollateral, cases, success) = calculateCaseCeccbDeltaRealBorrowAndDeltaRealCollateral(data);

        if (deltaFutureCollateral + data.futureCollateral < 0 && success) {
            return (deltaFutureCollateral, cases);
        }

        (deltaFutureCollateral, cases, success) =
            calculateCaseCecbDeltaRealBorrowAndDeltaRealCollateral(data, cacheDividend);

        if (!success) {
            revert IVaultErrors.DeltaRealBorrowAndDeltaRealCollateralUnexpectedError(data);
        }

        if (deltaFutureCollateral + data.futureCollateral < 0) {
            // we know data.futureCollateral > 0
            // mulDivUp

            if (
                (
                    deltaFutureCollateral
                        + data.futureCollateral.mulDivUp(
                            Constants.FUTURE_ADJUSTMENT_NUMERATOR, Constants.FUTURE_ADJUSTMENT_DENOMINATOR
                        ) > 0
                ) && (deltaFutureCollateral < 0)
            ) {
                deltaFutureCollateral = -data.futureCollateral;
            } else {
                revert IVaultErrors.DeltaRealBorrowAndDeltaRealCollateralUnexpectedError(data);
            }
        }

        return (deltaFutureCollateral, cases);
    }

    function negativeFutureCollateralBranchDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralData memory data
    ) internal pure returns (int256, Cases memory) {
        int256 deltaFutureCollateral;
        Cases memory cases;
        bool success;

        int256 cacheDividend = neutralDividendDeltaRealBorrowAndDeltaRealCollateral(data, false);

        (deltaFutureCollateral, cases, success) =
            calculateCaseCmcbDeltaRealBorrowAndDeltaRealCollateral(data, cacheDividend, true);

        if (deltaFutureCollateral < 0 && success) {
            return (deltaFutureCollateral, cases);
        }

        if (deltaFutureCollateral == 0 && success) {
            cases = CasesOperator.generateCase(6); // cna
            return (0, cases);
        }

        (deltaFutureCollateral, cases, success) = calculateCaseCecbcDeltaRealBorrowAndDeltaRealCollateral(data);

        if (deltaFutureCollateral + data.futureCollateral > 0 && success) {
            return (deltaFutureCollateral, cases);
        }

        (deltaFutureCollateral, cases, success) =
            calculateCaseCebcDeltaRealBorrowAndDeltaRealCollateral(data, cacheDividend);

        if (!success) {
            revert IVaultErrors.DeltaRealBorrowAndDeltaRealCollateralUnexpectedError(data);
        }

        if (deltaFutureCollateral + data.futureCollateral > 0) {
            // we know data.futureCollateral < 0
            // mulDivDown

            if (
                (
                    deltaFutureCollateral
                        + data.futureCollateral.mulDivDown(
                            Constants.FUTURE_ADJUSTMENT_NUMERATOR, Constants.FUTURE_ADJUSTMENT_DENOMINATOR
                        ) < 0
                ) && (deltaFutureCollateral > 0)
            ) {
                deltaFutureCollateral = -data.futureCollateral;
            } else {
                revert IVaultErrors.DeltaRealBorrowAndDeltaRealCollateralUnexpectedError(data);
            }
        }

        return (deltaFutureCollateral, cases);
    }

    function zeroFutureCollateralBranchDeltaRealBorrowAndDeltaRealCollateral(
        DeltaRealBorrowAndDeltaRealCollateralData memory data
    ) internal pure returns (int256, Cases memory) {
        int256 deltaFutureCollateral;
        Cases memory cases;
        bool success;

        // calc(cmbc)
        (deltaFutureCollateral, cases, success) = calculateCaseCmbcDeltaRealBorrowAndDeltaRealCollateral(data, 0, false);

        if (deltaFutureCollateral > 0 && success) {
            return (deltaFutureCollateral, cases);
        }

        (deltaFutureCollateral, cases, success) = calculateCaseCmcbDeltaRealBorrowAndDeltaRealCollateral(data, 0, false);

        if (deltaFutureCollateral < 0 && success) {
            return (deltaFutureCollateral, cases);
        }

        cases = CasesOperator.generateCase(6); // cna
        return (0, cases);
    }

    /**
     * ROUNDING:
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
        if (data.futureCollateral > 0) {
            return positiveFutureCollateralBranchDeltaRealBorrowAndDeltaRealCollateral(data);
        } else if (data.futureCollateral < 0) {
            return negativeFutureCollateralBranchDeltaRealBorrowAndDeltaRealCollateral(data);
        } else {
            return zeroFutureCollateralBranchDeltaRealBorrowAndDeltaRealCollateral(data);
        }
    }
}
