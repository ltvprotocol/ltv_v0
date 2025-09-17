// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IVaultErrors} from "src/errors/IVaultErrors.sol";
import {Constants} from "src/constants/Constants.sol";
import {Cases} from "src/structs/data/vault/common/Cases.sol";
import {DeltaSharesAndDeltaRealCollateralData} from
    "src/structs/data/vault/delta_real_collateral/DeltaSharesAndDeltaRealCollateralData.sol";
import {DeltaSharesAndDeltaRealCollateralDividendData} from
    "src/structs/data/vault/delta_real_collateral/DeltaSharesAndDeltaRealCollateralDividendData.sol";
import {DeltaSharesAndDeltaRealCollateralDividerData} from
    "src/structs/data/vault/delta_real_collateral/DeltaSharesAndDeltaRealCollateralDividerData.sol";
import {CasesOperator} from "src/math/libraries/CasesOperator.sol";
import {UMulDiv, SMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title DeltaSharesAndDeltaRealCollateral
 * @notice This library contains functions to calculate deltaFutureCollateral by deltaShares and deltaRealCollateral.
 *
 * @dev These calculations are derived from the ltv protocol paper. This function calculates deltaFutureCollateral
 * when deltaShares and deltaRealCollateral are provided. It goes through all the possible cases to find the valid deltaFutureCollateral.
 * Depending on the current auction direction only some cases are possible. Since you can't execute collateral to borrow auction when
 * borrow to collateral auction is in progress, and vice versa.
 */
library DeltaSharesAndDeltaRealCollateral {
    using UMulDiv for uint256;
    using SMulDiv for int256;

    function calculateDividentByDeltaSharesAndRealCollateral(
        DeltaSharesAndDeltaRealCollateralDividendData memory data,
        bool needToRoundUp
    ) private pure returns (int256) {
        // borrow
        // (1 - targetLtv) x deltaRealCollateral
        // (1 - targetLtv) x ceccb x -userFutureRewardCollateral
        // (1 - targetLtv) x cecbc x -futureCollateral x collateralSlippage
        // cecbc x - protocolFutureRewardBorrow
        // -shares
        // -targetLtv x collateral
        // targetLtv x ceccb x protocolFutureRewardCollateral

        int256 dividend = int256(data.borrow);
        dividend -= int256(int8(data.cases.cecbc)) * data.protocolFutureRewardBorrow;
        dividend -= data.deltaShares;

        int256 dividendWithtargetLtv = -int256(data.collateral);
        dividendWithtargetLtv += int256(int8(data.cases.ceccb)) * data.protocolFutureRewardCollateral;

        int256 dividendWithOneMinustargetLtv = data.deltaRealCollateral;
        dividendWithOneMinustargetLtv -= int256(int8(data.cases.ceccb)) * int256(data.userFutureRewardCollateral);

        dividendWithOneMinustargetLtv += int256(int8(data.cases.cecbc))
            * (-data.futureCollateral).mulDiv(int256(data.collateralSlippage), Constants.SLIPPAGE_PRECISION, needToRoundUp);

        dividend += dividendWithOneMinustargetLtv.mulDiv(
            int256(uint256(data.targetLtvDivider) - uint256(data.targetLtvDividend)),
            int256(uint256(data.targetLtvDivider)),
            needToRoundUp
        );
        dividend += dividendWithtargetLtv.mulDiv(
            int256(uint256(data.targetLtvDividend)), int256(uint256(data.targetLtvDivider)), needToRoundUp
        );

        return dividend;
    }

    // divider is always negative
    function calculateDividerByDeltaSharesAndDeltaRealCollateral(
        DeltaSharesAndDeltaRealCollateralDividerData memory data,
        bool needToRoundUp
    ) private pure returns (int256) {
        // (1 - targetLtv) x -1
        // (1 - targetLtv) x cecb x (userFutureRewardCollateral / futureCollateral) x -1
        // (1 - targetLtv) x cmbc x collateralSlippage
        // (1 - targetLtv) x cecbc x collateralSlippage
        // cebc x (protocolFutureRewardBorrow / futureCollateral) x -1
        // targetLtv x cecb x (protocolFutureRewardCollateral / futureCollateral)

        int256 dividerWithOneMinustargetLtv = -Constants.DIVIDER_PRECISION;
        int256 divider;
        if (data.futureCollateral != 0) {
            dividerWithOneMinustargetLtv += int256(int8(data.cases.cecb))
                * (-data.userFutureRewardCollateral).mulDiv(
                    Constants.DIVIDER_PRECISION, data.futureCollateral, needToRoundUp
                );

            divider += int256(int8(data.cases.cebc))
                * (-data.protocolFutureRewardBorrow).mulDiv(
                    Constants.DIVIDER_PRECISION, data.futureCollateral, needToRoundUp
                );

            divider += int256(int8(data.cases.cecb))
                * (data.protocolFutureRewardCollateral).mulDiv(
                    (Constants.DIVIDER_PRECISION * int256(uint256(data.targetLtvDividend))),
                    (data.futureCollateral * int256(uint256(data.targetLtvDivider))),
                    needToRoundUp
                );
        }

        dividerWithOneMinustargetLtv += int256(int8(data.cases.cecbc)) * int256(data.collateralSlippage);
        dividerWithOneMinustargetLtv += int256(int8(data.cases.cmbc)) * int256(data.collateralSlippage);

        divider += dividerWithOneMinustargetLtv.mulDiv(
            int256(uint256(data.targetLtvDivider - data.targetLtvDividend)),
            int256(uint256(data.targetLtvDivider)),
            needToRoundUp
        );

        return divider;
    }

    function calculateSingleCaseDeltaSharesAndDeltaRealCollateral(
        DeltaSharesAndDeltaRealCollateralData memory data,
        bool needToRoundUpDividend,
        bool needToRoundUpDivider
    ) private pure returns (int256, bool) {
        int256 dividend = calculateDividentByDeltaSharesAndRealCollateral(
            DeltaSharesAndDeltaRealCollateralDividendData({
                cases: data.cases,
                borrow: data.borrow,
                deltaRealCollateral: data.deltaRealCollateral,
                userFutureRewardCollateral: data.userFutureRewardCollateral,
                futureCollateral: data.futureCollateral,
                collateralSlippage: data.collateralSlippage,
                protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                deltaShares: data.deltaShares,
                collateral: data.collateral,
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider
            }),
            needToRoundUpDividend
        );

        int256 divider = calculateDividerByDeltaSharesAndDeltaRealCollateral(
            DeltaSharesAndDeltaRealCollateralDividerData({
                cases: data.cases,
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                userFutureRewardCollateral: data.userFutureRewardCollateral,
                futureCollateral: data.futureCollateral,
                collateralSlippage: data.collateralSlippage,
                protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: data.protocolFutureRewardCollateral
            }),
            needToRoundUpDivider
        );

        if (divider == 0) {
            return (0, false);
        }

        bool needToRoundUp = !needToRoundUpDividend;
        int256 deltaFutureCollateral = dividend.mulDiv(Constants.DIVIDER_PRECISION, divider, needToRoundUp);

        return (deltaFutureCollateral, true);
    }

    function calculateSingleCaseCacheDividendDeltaSharesAndDeltaRealCollateral(
        DeltaSharesAndDeltaRealCollateralData memory data,
        bool needToRoundUpDividend,
        bool needToRoundUpDivider,
        int256 dividend
    ) private pure returns (int256, bool) {
        int256 divider = calculateDividerByDeltaSharesAndDeltaRealCollateral(
            DeltaSharesAndDeltaRealCollateralDividerData({
                cases: data.cases,
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                userFutureRewardCollateral: data.userFutureRewardCollateral,
                futureCollateral: data.futureCollateral,
                collateralSlippage: data.collateralSlippage,
                protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: data.protocolFutureRewardCollateral
            }),
            needToRoundUpDivider
        );

        if (divider == 0) {
            return (0, false);
        }

        bool needToRoundUp = !needToRoundUpDividend;
        int256 deltaFutureCollateral = dividend.mulDiv(Constants.DIVIDER_PRECISION, divider, needToRoundUp);

        return (deltaFutureCollateral, true);
    }

    function calculateCaseCmcbDeltaSharesAndDeltaRealCollateral(
        DeltaSharesAndDeltaRealCollateralData memory data,
        int256 cacheDividend,
        bool cache
    ) private pure returns (int256, Cases memory, bool) {
        data.cases = CasesOperator.generateCase(0); // cmcb case

        int256 deltaFutureCollateral;
        bool success;

        if (cache) {
            (deltaFutureCollateral, success) =
                calculateSingleCaseCacheDividendDeltaSharesAndDeltaRealCollateral(data, true, true, cacheDividend);
        } else {
            (deltaFutureCollateral, success) = calculateSingleCaseDeltaSharesAndDeltaRealCollateral(data, true, true);
        }

        return (deltaFutureCollateral, data.cases, success);
    }

    function calculateCaseCmbcDeltaSharesAndDeltaRealCollateral(
        DeltaSharesAndDeltaRealCollateralData memory data,
        int256 cacheDividend,
        bool cache
    ) private pure returns (int256, Cases memory, bool) {
        data.cases = CasesOperator.generateCase(1); // cmbc case

        int256 deltaFutureCollateral;
        bool success;

        if (cache) {
            (deltaFutureCollateral, success) =
                calculateSingleCaseCacheDividendDeltaSharesAndDeltaRealCollateral(data, false, true, cacheDividend);
        } else {
            (deltaFutureCollateral, success) = calculateSingleCaseDeltaSharesAndDeltaRealCollateral(data, false, true);
        }

        return (deltaFutureCollateral, data.cases, success);
    }

    function calculateCaseCecbDeltaSharesAndDeltaRealCollateral(
        DeltaSharesAndDeltaRealCollateralData memory data,
        int256 cacheDividend
    ) private pure returns (int256, Cases memory, bool) {
        data.cases = CasesOperator.generateCase(2); // cecb case
        (int256 deltaFutureCollateral, bool success) =
            calculateSingleCaseCacheDividendDeltaSharesAndDeltaRealCollateral(data, false, false, cacheDividend);
        return (deltaFutureCollateral, data.cases, success);
    }

    function calculateCaseCebcDeltaSharesAndDeltaRealCollateral(
        DeltaSharesAndDeltaRealCollateralData memory data,
        int256 cacheDividend
    ) private pure returns (int256, Cases memory, bool) {
        data.cases = CasesOperator.generateCase(3); // cebc case
        (int256 deltaFutureCollateral, bool success) =
            calculateSingleCaseCacheDividendDeltaSharesAndDeltaRealCollateral(data, true, false, cacheDividend);
        return (deltaFutureCollateral, data.cases, success);
    }

    function calculateCaseCeccbDeltaSharesAndDeltaRealCollateral(DeltaSharesAndDeltaRealCollateralData memory data)
        private
        pure
        returns (int256, Cases memory, bool)
    {
        data.cases = CasesOperator.generateCase(4); // ceccb case
        (int256 deltaFutureCollateral, bool success) =
            calculateSingleCaseDeltaSharesAndDeltaRealCollateral(data, true, true);
        return (deltaFutureCollateral, data.cases, success);
    }

    function calculateCaseCecbcDeltaSharesAndDeltaRealCollateral(DeltaSharesAndDeltaRealCollateralData memory data)
        private
        pure
        returns (int256, Cases memory, bool)
    {
        data.cases = CasesOperator.generateCase(5); // cecbc case
        (int256 deltaFutureCollateral, bool success) =
            calculateSingleCaseDeltaSharesAndDeltaRealCollateral(data, false, true);
        return (deltaFutureCollateral, data.cases, success);
    }

    function neutralDividendDeltaSharesAndDeltaRealCollateral(
        DeltaSharesAndDeltaRealCollateralData memory data,
        bool needToRoundUpDividend
    ) private pure returns (int256 dividend) {
        data.cases = CasesOperator.generateCase(6); // cna case - neutral case

        dividend = calculateDividentByDeltaSharesAndRealCollateral(
            DeltaSharesAndDeltaRealCollateralDividendData({
                cases: data.cases,
                borrow: data.borrow,
                deltaRealCollateral: data.deltaRealCollateral,
                userFutureRewardCollateral: data.userFutureRewardCollateral,
                futureCollateral: data.futureCollateral,
                collateralSlippage: data.collateralSlippage,
                protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                deltaShares: data.deltaShares,
                collateral: data.collateral,
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider
            }),
            needToRoundUpDividend
        );
    }

    function positiveFutureCollateralBranchDeltaSharesAndDeltaRealCollateral(
        DeltaSharesAndDeltaRealCollateralData memory data
    ) private pure returns (int256, Cases memory) {
        int256 deltaFutureCollateral;
        Cases memory cases;
        bool success;

        int256 cacheDividend = neutralDividendDeltaSharesAndDeltaRealCollateral(data, false);

        (deltaFutureCollateral, cases, success) =
            calculateCaseCmbcDeltaSharesAndDeltaRealCollateral(data, cacheDividend, true);

        if (deltaFutureCollateral > 0 && success) {
            return (deltaFutureCollateral, cases);
        }

        if (deltaFutureCollateral == 0 && success) {
            cases = CasesOperator.generateCase(6); // cna
            return (0, cases);
        }

        (deltaFutureCollateral, cases, success) = calculateCaseCeccbDeltaSharesAndDeltaRealCollateral(data);

        if (deltaFutureCollateral + data.futureCollateral < 0 && success) {
            return (deltaFutureCollateral, cases);
        }

        (deltaFutureCollateral, cases, success) =
            calculateCaseCecbDeltaSharesAndDeltaRealCollateral(data, cacheDividend);

        if (!success) {
            revert IVaultErrors.DeltaSharesAndDeltaRealCollateralUnexpectedError(data);
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
                revert IVaultErrors.DeltaSharesAndDeltaRealCollateralUnexpectedError(data);
            }
        }

        return (deltaFutureCollateral, cases);
    }

    function negativeFutureCollateralBranchDeltaSharesAndDeltaRealCollateral(
        DeltaSharesAndDeltaRealCollateralData memory data
    ) private pure returns (int256, Cases memory) {
        int256 deltaFutureCollateral;
        Cases memory cases;
        bool success;

        int256 cacheDividend = neutralDividendDeltaSharesAndDeltaRealCollateral(data, false);

        (deltaFutureCollateral, cases, success) =
            calculateCaseCmcbDeltaSharesAndDeltaRealCollateral(data, cacheDividend, true);

        if (deltaFutureCollateral < 0 && success) {
            return (deltaFutureCollateral, cases);
        }

        if (deltaFutureCollateral == 0 && success) {
            cases = CasesOperator.generateCase(6); // cna
            return (0, cases);
        }

        (deltaFutureCollateral, cases, success) = calculateCaseCecbcDeltaSharesAndDeltaRealCollateral(data);

        if (deltaFutureCollateral + data.futureCollateral > 0 && success) {
            return (deltaFutureCollateral, cases);
        }

        (deltaFutureCollateral, cases, success) =
            calculateCaseCebcDeltaSharesAndDeltaRealCollateral(data, cacheDividend);

        if (!success) {
            revert IVaultErrors.DeltaSharesAndDeltaRealCollateralUnexpectedError(data);
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
                revert IVaultErrors.DeltaSharesAndDeltaRealCollateralUnexpectedError(data);
            }
        }

        return (deltaFutureCollateral, cases);
    }

    function zeroFutureCollateralBranchDeltaSharesAndDeltaRealCollateral(
        DeltaSharesAndDeltaRealCollateralData memory data
    ) private pure returns (int256, Cases memory) {
        int256 deltaFutureCollateral;
        Cases memory cases;
        bool success;

        (deltaFutureCollateral, cases, success) = calculateCaseCmbcDeltaSharesAndDeltaRealCollateral(data, 0, false);

        if (deltaFutureCollateral > 0 && success) {
            return (deltaFutureCollateral, cases);
        }

        (deltaFutureCollateral, cases, success) = calculateCaseCmcbDeltaSharesAndDeltaRealCollateral(data, 0, false);

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
     * cmcb, ceccb - deltaFutureCollateral < 0 and rounding down. dividend > 0, divider < 0, round dividend up, round divider up
     * cebc - deltaFutureCollateral > 0 and rounding down. So dividend < 0, divider < 0, round dividend up, round divider down
     * cmbc, cecbc - deltaFutureCollateral > 0 and rounding up. So dividend < 0, divider < 0, round dividend down, round divider up
     * cecb - deltaFutureCollateral < 0 and rounding up. So dividend > 0, divider < 0, round dividend down, round divider down
     *
     * ROUNDING DIVIDEND/DIVIDER:
     * cmcb, cebc, ceccb - round down
     * cecb, cecbc, cmbc - round up
     *
     * ROUNDING DIVIDER:
     * cmcb, ceccb, cmbc, cecbc - roundind up
     * cebc, cecb - rounding down
     *
     * ROUDNING DIVIDEND:
     * cmcb, ceccb, cebc - rounding up
     * cmcb, cecbc, cecb - rounding down
     */
    function calculateDeltaFutureCollateralByDeltaSharesAndDeltaRealCollateral(
        DeltaSharesAndDeltaRealCollateralData memory data
    ) external pure returns (int256, Cases memory) {
        if (data.futureCollateral > 0) {
            return positiveFutureCollateralBranchDeltaSharesAndDeltaRealCollateral(data);
        } else if (data.futureCollateral < 0) {
            return negativeFutureCollateralBranchDeltaSharesAndDeltaRealCollateral(data);
        } else {
            return zeroFutureCollateralBranchDeltaSharesAndDeltaRealCollateral(data);
        }
    }
}
