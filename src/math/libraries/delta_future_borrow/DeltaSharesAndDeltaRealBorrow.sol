// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IVaultErrors} from "src/errors/IVaultErrors.sol";
import {Constants} from "src/constants/Constants.sol";
import {Cases} from "src/structs/data/vault/common/Cases.sol";
import {DeltaSharesAndDeltaRealBorrowData} from
    "src/structs/data/vault/delta_real_borrow/DeltaSharesAndDeltaRealBorrowData.sol";
import {DeltaSharesAndDeltaRealBorrowDividendData} from
    "src/structs/data/vault/delta_real_borrow/DeltaSharesAndDeltaRealBorrowDividendData.sol";
import {DeltaSharesAndDeltaRealBorrowDividerData} from
    "src/structs/data/vault/delta_real_borrow/DeltaSharesAndDeltaRealBorrowDividerData.sol";
import {CasesOperator} from "src/math/libraries/CasesOperator.sol";
import {UMulDiv, SMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title DeltaSharesAndDeltaRealBorrow
 * @notice This library contains functions to calculate deltaFutureBorrow by deltaShares and deltaRealBorrow.
 *
 * @dev These calculations are derived from the ltv protocol paper. This function calculates deltaFutureBorrow
 * when deltaShares and deltaRealBorrow are provided. It goes through all the cases to find the valid deltaFutureBorrow.
 * Depending on the current auction direction only some cases are possible. Since you can't execute borrow to collateral auction when
 * collateral to borrow auction is in progress, and vice versa.
 */
library DeltaSharesAndDeltaRealBorrow {
    using UMulDiv for uint256;
    using SMulDiv for int256;

    /**
     * @notice Calculates the dividend component for delta future borrow calculation
     * @dev This function computes the numerator of the delta future borrow formula based on the LTV protocol paper.
     * @param data The dividend calculation data containing all necessary parameters
     * @param needToRoundUp Whether to round up the calculation results (true = round up, false = round down)
     * @return The calculated dividend value for delta future borrow
     */
    function calculateDividentByDeltaSharesAndDeltaRealBorrow(
        DeltaSharesAndDeltaRealBorrowDividendData memory data,
        bool needToRoundUp
    ) private pure returns (int256) {
        // borrow
        // (1 - targetLtv) x deltaRealBorrow
        // (1 - targetLtv) x cecbc x -userFutureRewardBorrow
        // (1 - targetLtv) x ceccb x -futureBorrow x borrowSlippage
        // cecbc x - protocolFutureRewardBorrow
        // -targetLtv x collateral
        // -targetLtv x \Delta shares
        // -targetLtv x ceccb x - protocolFutureRewardCollateral

        int256 dividend = int256(data.borrow);
        dividend -= int256(int8(data.cases.cecbc)) * data.protocolFutureRewardBorrow;

        int256 dividendWithOneMinustargetLtv = data.deltaRealBorrow;
        dividendWithOneMinustargetLtv -= int256(int8(data.cases.cecbc)) * int256(data.userFutureRewardBorrow);
        dividendWithOneMinustargetLtv += int256(int8(data.cases.ceccb))
            * int256(-data.futureBorrow).mulDiv(int256(data.borrowSlippage), Constants.SLIPPAGE_PRECISION, needToRoundUp);

        int256 dividendWithtargetLtv = -int256(data.collateral);
        dividendWithtargetLtv -= data.deltaShares;
        dividendWithtargetLtv += int256(int8(data.cases.ceccb)) * data.protocolFutureRewardCollateral;

        dividend += dividendWithOneMinustargetLtv.mulDiv(
            int256(uint256(data.targetLtvDivider - data.targetLtvDividend)),
            int256(uint256(data.targetLtvDivider)),
            needToRoundUp
        );
        dividend += dividendWithtargetLtv.mulDiv(
            int256(uint256(data.targetLtvDividend)), int256(uint256(data.targetLtvDivider)), needToRoundUp
        );

        return dividend;
    }

    /**
     * @notice Calculates the divider component for delta future borrow calculation
     * @dev This function computes the denominator of the delta future borrow formula.
     * @param data The divider calculation data containing all necessary parameters
     * @param needToRoundUp Whether to round up the calculation results (true = round up, false = round down)
     * @return The calculated divider value (always negative)
     */
    function calculateDividerByDeltaSharesAndDeltaRealBorrow(
        DeltaSharesAndDeltaRealBorrowDividerData memory data,
        bool needToRoundUp
    ) private pure returns (int256) {
        // (1 - targetLtv) x -1
        // (1 - targetLtv) x cebc x -(userFutureRewardBorrow / futureBorrow)
        // (1 - targetLtv) x cmcb x borrowSlippage
        // (1 - targetLtv) x ceccb x borrowSlippage
        // cebc x -(protocolFutureRewardBorrow / futureBorrow)
        // -targetLtv x cecb x -(protocolFutureRewardCollateral / futureBorrow)

        int256 dividerWithOneMinustargetLtv = -Constants.DIVIDER_PRECISION;
        int256 divider;

        if (data.futureBorrow != 0) {
            dividerWithOneMinustargetLtv += int256(int8(data.cases.cebc))
                * (-data.userFutureRewardBorrow).mulDiv(Constants.DIVIDER_PRECISION, data.futureBorrow, needToRoundUp);

            divider += int256(int8(data.cases.cebc))
                * (-data.protocolFutureRewardBorrow).mulDiv(Constants.DIVIDER_PRECISION, data.futureBorrow, needToRoundUp);

            divider += int256(int8(data.cases.cecb))
                * data.protocolFutureRewardCollateral.mulDiv(
                    (Constants.DIVIDER_PRECISION * int256(uint256(data.targetLtvDividend))),
                    (data.futureBorrow * int256(uint256(data.targetLtvDivider))),
                    needToRoundUp
                );
        }

        dividerWithOneMinustargetLtv += int256(int8(data.cases.ceccb)) * int256(data.borrowSlippage);
        dividerWithOneMinustargetLtv += int256(int8(data.cases.cmcb)) * int256(data.borrowSlippage);
        divider += dividerWithOneMinustargetLtv.mulDiv(
            int256(uint256(data.targetLtvDivider - data.targetLtvDividend)),
            int256(uint256(data.targetLtvDivider)),
            needToRoundUp
        );

        return divider;
    }

    /**
     * @notice Calculates delta future borrow for a single case scenario
     * @dev This function computes the delta future borrow by dividing the dividend by the divider.
     *      It handles the case where divider is zero and applies appropriate rounding.
     * @param data The input data for the calculation
     * @param needToRoundUpDividend Whether to round up the dividend calculation (true = round up, false = round down)
     * @param needToRoundUpDivider Whether to round up the divider calculation (true = round up, false = round down)
     * @return deltaFutureBorrow The calculated delta future borrow value
     * @return success Whether the calculation was successful (divider != 0)
     */
    function calculateSingleCaseDeltaSharesAndDeltaRealBorrow(
        DeltaSharesAndDeltaRealBorrowData memory data,
        bool needToRoundUpDividend,
        bool needToRoundUpDivider
    ) private pure returns (int256, bool) {
        int256 dividend = calculateDividentByDeltaSharesAndDeltaRealBorrow(
            DeltaSharesAndDeltaRealBorrowDividendData({
                borrow: data.borrow,
                collateral: data.collateral,
                protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                userFutureRewardBorrow: data.userFutureRewardBorrow,
                futureBorrow: data.futureBorrow,
                borrowSlippage: data.borrowSlippage,
                deltaRealBorrow: data.deltaRealBorrow,
                deltaShares: data.deltaShares,
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                cases: data.cases
            }),
            needToRoundUpDividend
        );

        int256 divider = calculateDividerByDeltaSharesAndDeltaRealBorrow(
            DeltaSharesAndDeltaRealBorrowDividerData({
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                userFutureRewardBorrow: data.userFutureRewardBorrow,
                futureBorrow: data.futureBorrow,
                borrowSlippage: data.borrowSlippage,
                protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                cases: data.cases
            }),
            needToRoundUpDivider
        );

        if (divider == 0) {
            return (0, false);
        }

        bool needToRoundUp = !needToRoundUpDividend;
        int256 deltaFutureBorrow = dividend.mulDiv(Constants.DIVIDER_PRECISION, divider, needToRoundUp);

        return (deltaFutureBorrow, true);
    }

    /**
     * @notice Calculates delta future borrow using a cached dividend value
     * @dev This function is an optimized version that reuses a pre-calculated dividend
     *      to avoid redundant calculations when multiple cases share the same dividend.
     * @param data The input data for the calculation
     * @param needToRoundUpDividend Whether to round up the dividend calculation (true = round up, false = round down)
     * @param needToRoundUpDivider Whether to round up the divider calculation (true = round up, false = round down)
     * @param dividend The pre-calculated dividend value to use
     * @return deltaFutureBorrow The calculated delta future borrow value
     * @return success Whether the calculation was successful (divider != 0)
     */
    function calculateSingleCaseCacheDividendDeltaSharesAndDeltaRealBorrow(
        DeltaSharesAndDeltaRealBorrowData memory data,
        bool needToRoundUpDividend,
        bool needToRoundUpDivider,
        int256 dividend
    ) private pure returns (int256, bool) {
        int256 divider = calculateDividerByDeltaSharesAndDeltaRealBorrow(
            DeltaSharesAndDeltaRealBorrowDividerData({
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                userFutureRewardBorrow: data.userFutureRewardBorrow,
                futureBorrow: data.futureBorrow,
                borrowSlippage: data.borrowSlippage,
                protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                cases: data.cases
            }),
            needToRoundUpDivider
        );

        if (divider == 0) {
            return (0, false);
        }

        bool needToRoundUp = !needToRoundUpDividend;
        int256 deltaFutureBorrow = dividend.mulDiv(Constants.DIVIDER_PRECISION, divider, needToRoundUp);

        return (deltaFutureBorrow, true);
    }

    /**
     * @notice Calculates delta future borrow for case CMCB
     * @dev This case represents a scenario where collateral is increased and borrow is decreased.
     *      Uses specific rounding rules: dividend up, divider up.
     * @param data The input data for the calculation
     * @param cacheDividend Pre-calculated dividend value for optimization
     * @param cache Whether to use the cached dividend value
     * @return deltaFutureBorrow The calculated delta future borrow value
     * @return cases The case configuration used
     * @return success Whether the calculation was successful
     */
    function calculateCaseCmcbDeltaSharesAndDeltaRealBorrow(
        DeltaSharesAndDeltaRealBorrowData memory data,
        int256 cacheDividend,
        bool cache
    ) private pure returns (int256, Cases memory, bool) {
        data.cases = CasesOperator.generateCase(0); // cmcb case

        int256 deltaFutureBorrow;
        bool success;

        if (cache) {
            (deltaFutureBorrow, success) =
                calculateSingleCaseCacheDividendDeltaSharesAndDeltaRealBorrow(data, true, true, cacheDividend);
        } else {
            (deltaFutureBorrow, success) = calculateSingleCaseDeltaSharesAndDeltaRealBorrow(data, true, true);
        }

        return (deltaFutureBorrow, data.cases, success);
    }

    /**
     * @notice Calculates delta future borrow for case CMBC
     * @param data The input data for the calculation
     * @param cacheDividend Pre-calculated dividend value for optimization
     * @param cache Whether to use the cached dividend value
     * @return deltaFutureBorrow The calculated delta future borrow value
     * @return cases The case configuration used
     * @return success Whether the calculation was successful
     */
    function calculateCaseCmbcDeltaSharesAndDeltaRealBorrow(
        DeltaSharesAndDeltaRealBorrowData memory data,
        int256 cacheDividend,
        bool cache
    ) private pure returns (int256, Cases memory, bool) {
        data.cases = CasesOperator.generateCase(1); // cmbc case

        int256 deltaFutureBorrow;
        bool success;

        if (cache) {
            (deltaFutureBorrow, success) =
                calculateSingleCaseCacheDividendDeltaSharesAndDeltaRealBorrow(data, false, true, cacheDividend);
        } else {
            (deltaFutureBorrow, success) = calculateSingleCaseDeltaSharesAndDeltaRealBorrow(data, false, true);
        }

        return (deltaFutureBorrow, data.cases, success);
    }

    /**
     * @notice Calculates delta future borrow for case CECB
     * @param data The input data for the calculation
     * @param cacheDividend Pre-calculated dividend value for optimization
     * @return deltaFutureBorrow The calculated delta future borrow value
     * @return cases The case configuration used
     * @return success Whether the calculation was successful
     */
    function calculateCaseCecbDeltaSharesAndDeltaRealBorrow(
        DeltaSharesAndDeltaRealBorrowData memory data,
        int256 cacheDividend
    ) private pure returns (int256, Cases memory, bool) {
        data.cases = CasesOperator.generateCase(2); // cecb case
        (int256 deltaFutureBorrow, bool success) =
            calculateSingleCaseCacheDividendDeltaSharesAndDeltaRealBorrow(data, false, false, cacheDividend);
        return (deltaFutureBorrow, data.cases, success);
    }

    /**
     * @notice Calculates delta future borrow for case CEBC
     * @param data The input data for the calculation
     * @param cacheDividend Pre-calculated dividend value for optimization
     * @return deltaFutureBorrow The calculated delta future borrow value
     * @return cases The case configuration used
     * @return success Whether the calculation was successful
     */
    function calculateCaseCebcDeltaSharesAndDeltaRealBorrow(
        DeltaSharesAndDeltaRealBorrowData memory data,
        int256 cacheDividend
    ) private pure returns (int256, Cases memory, bool) {
        data.cases = CasesOperator.generateCase(3); // cebc case
        (int256 deltaFutureBorrow, bool success) =
            calculateSingleCaseCacheDividendDeltaSharesAndDeltaRealBorrow(data, true, false, cacheDividend);
        return (deltaFutureBorrow, data.cases, success);
    }

    /**
     * @notice Calculates delta future borrow for case CECCB
     * @param data The input data for the calculation
     * @return deltaFutureBorrow The calculated delta future borrow value
     * @return cases The case configuration used
     * @return success Whether the calculation was successful
     */
    function calculateCaseCeccbDeltaSharesAndDeltaRealBorrow(DeltaSharesAndDeltaRealBorrowData memory data)
        private
        pure
        returns (int256, Cases memory, bool)
    {
        data.cases = CasesOperator.generateCase(4); // ceccb case
        (int256 deltaFutureBorrow, bool success) = calculateSingleCaseDeltaSharesAndDeltaRealBorrow(data, true, true);
        return (deltaFutureBorrow, data.cases, success);
    }

    /**
     * @notice Calculates delta future borrow for case CECBC
     * @param data The input data for the calculation
     * @return deltaFutureBorrow The calculated delta future borrow value
     * @return cases The case configuration used
     * @return success Whether the calculation was successful
     */
    function calculateCaseCecbcDeltaSharesAndDeltaRealBorrow(DeltaSharesAndDeltaRealBorrowData memory data)
        private
        pure
        returns (int256, Cases memory, bool)
    {
        data.cases = CasesOperator.generateCase(5); // cecbc case
        (int256 deltaFutureBorrow, bool success) = calculateSingleCaseDeltaSharesAndDeltaRealBorrow(data, false, true);
        return (deltaFutureBorrow, data.cases, success);
    }

    /**
     * Calculates the neutral dividend for delta shares and delta real borrow
     * @param data The input data for the calculation
     * @param needToRoundUpDividend Whether to round up the dividend calculation (true = round up, false = round down)
     * @return dividend The calculated dividend value
     */
    function neutralDividendDeltaSharesAndDeltaRealBorrow(
        DeltaSharesAndDeltaRealBorrowData memory data,
        bool needToRoundUpDividend
    ) private pure returns (int256 dividend) {
        data.cases = CasesOperator.generateCase(6); // cna case - neutral case

        dividend = calculateDividentByDeltaSharesAndDeltaRealBorrow(
            DeltaSharesAndDeltaRealBorrowDividendData({
                borrow: data.borrow,
                collateral: data.collateral,
                protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                userFutureRewardBorrow: data.userFutureRewardBorrow,
                futureBorrow: data.futureBorrow,
                borrowSlippage: data.borrowSlippage,
                deltaRealBorrow: data.deltaRealBorrow,
                deltaShares: data.deltaShares,
                targetLtvDividend: data.targetLtvDividend,
                targetLtvDivider: data.targetLtvDivider,
                cases: data.cases
            }),
            needToRoundUpDividend
        );
    }

    /**
     * @notice Handles the calculation branch when future borrow is positive
     * @dev This function processes cases where the current future borrow amount is positive.
     * @param data The input data for the calculation
     * @return deltaFutureBorrow The calculated delta future borrow value
     * @return cases The case configuration that produced a valid result
     */
    function positiveBranchDeltaSharesAndDeltaRealBorrow(DeltaSharesAndDeltaRealBorrowData memory data)
        private
        pure
        returns (int256, Cases memory)
    {
        int256 deltaFutureBorrow;
        Cases memory cases;
        bool success;

        int256 cacheDividend = neutralDividendDeltaSharesAndDeltaRealBorrow(data, false);

        (deltaFutureBorrow, cases, success) = calculateCaseCmbcDeltaSharesAndDeltaRealBorrow(data, cacheDividend, true);

        if (deltaFutureBorrow > 0 && success) {
            return (deltaFutureBorrow, cases);
        }

        if (deltaFutureBorrow == 0 && success) {
            cases = CasesOperator.generateCase(6); // cna
            return (0, cases);
        }

        (deltaFutureBorrow, cases, success) = calculateCaseCeccbDeltaSharesAndDeltaRealBorrow(data);

        if (deltaFutureBorrow + data.futureBorrow < 0 && success) {
            return (deltaFutureBorrow, cases);
        }

        (deltaFutureBorrow, cases, success) = calculateCaseCecbDeltaSharesAndDeltaRealBorrow(data, cacheDividend);

        if (!success) {
            revert IVaultErrors.DeltaSharesAndDeltaRealBorrowUnexpectedError(data);
        }

        if (deltaFutureBorrow + data.futureBorrow < 0) {
            // we know data.futureBorrow > 0
            // mulDivUp

            if (
                (
                    deltaFutureBorrow
                        + data.futureBorrow.mulDivUp(
                            Constants.FUTURE_ADJUSTMENT_NUMERATOR, Constants.FUTURE_ADJUSTMENT_DENOMINATOR
                        ) > 0
                ) && (deltaFutureBorrow < 0)
            ) {
                deltaFutureBorrow = -data.futureBorrow;
            } else {
                revert IVaultErrors.DeltaSharesAndDeltaRealBorrowUnexpectedError(data);
            }
        }

        return (deltaFutureBorrow, cases);
    }

    /**
     * @notice Handles the calculation branch when future borrow is negative
     * @dev This function processes cases where the current future borrow amount is negative.
     * @param data The input data for the calculation
     * @return deltaFutureBorrow The calculated delta future borrow value
     * @return cases The case configuration that produced a valid result
     */
    function negativeBranchDeltaSharesAndDeltaRealBorrow(DeltaSharesAndDeltaRealBorrowData memory data)
        private
        pure
        returns (int256, Cases memory)
    {
        int256 deltaFutureBorrow;
        Cases memory cases;
        bool success;

        int256 cacheDividend = neutralDividendDeltaSharesAndDeltaRealBorrow(data, true);

        (deltaFutureBorrow, cases, success) = calculateCaseCmcbDeltaSharesAndDeltaRealBorrow(data, cacheDividend, true);

        if (deltaFutureBorrow < 0 && success) {
            return (deltaFutureBorrow, cases);
        }
        if (deltaFutureBorrow == 0 && success) {
            cases = CasesOperator.generateCase(6); // cna
            return (0, cases);
        }

        (deltaFutureBorrow, cases, success) = calculateCaseCecbcDeltaSharesAndDeltaRealBorrow(data);

        if (deltaFutureBorrow + data.futureBorrow > 0 && success) {
            return (deltaFutureBorrow, cases);
        }

        (deltaFutureBorrow, cases, success) = calculateCaseCebcDeltaSharesAndDeltaRealBorrow(data, cacheDividend);

        if (!success) {
            revert IVaultErrors.DeltaSharesAndDeltaRealBorrowUnexpectedError(data);
        }

        if (deltaFutureBorrow + data.futureBorrow > 0) {
            // we know data.futureBorrow < 0
            // mulDivDown

            if (
                (
                    deltaFutureBorrow
                        + data.futureBorrow.mulDivDown(
                            Constants.FUTURE_ADJUSTMENT_NUMERATOR, Constants.FUTURE_ADJUSTMENT_DENOMINATOR
                        ) < 0
                ) && (deltaFutureBorrow > 0)
            ) {
                deltaFutureBorrow = -data.futureBorrow;
            } else {
                revert IVaultErrors.DeltaSharesAndDeltaRealBorrowUnexpectedError(data);
            }
        }

        return (deltaFutureBorrow, cases);
    }

    /**
     * @notice Handles the calculation branch when future borrow is zero
     * @dev This function processes cases where the current future borrow amount is zero.
     * @param data The input data for the calculation
     * @return deltaFutureBorrow The calculated delta future borrow value
     * @return cases The case configuration that produced a valid result
     */
    function zeroBranchDeltaSharesAndDeltaRealBorrow(DeltaSharesAndDeltaRealBorrowData memory data)
        private
        pure
        returns (int256, Cases memory)
    {
        int256 deltaFutureBorrow;
        Cases memory cases;
        bool success;

        (deltaFutureBorrow, cases, success) = calculateCaseCmbcDeltaSharesAndDeltaRealBorrow(data, 0, false);

        if (deltaFutureBorrow > 0 && success) {
            return (deltaFutureBorrow, cases);
        }

        (deltaFutureBorrow, cases, success) = calculateCaseCmcbDeltaSharesAndDeltaRealBorrow(data, 0, false);

        if (deltaFutureBorrow < 0 && success) {
            return (deltaFutureBorrow, cases);
        }

        cases = CasesOperator.generateCase(6); // cna
        return (0, cases);
    }

    /**
     * ROUNDING:
     * For every single case we need to round deltaFutureBorrow in the way to help case to
     * be valid
     * cmcb: For this case deltaFutureBorrow < 0. To help it be indeed negative we need to round deltaFutureBorrow to the bottom
     * cebc: deltaFutureBorrow > 0, but deltaFutureBorrow < -futureBorrow. So round it down. In case
     * deltaFutureBorrow == 0 this case will be interpretted as cna
     * cecbc: deltaFutureBorrow > 0 and deltaFutureBorrow > -futureBorrow. So round it up
     * cecb: deltaFutureBorrow < 0, but deltaFutureBorrow > -futureBorrow. So round it up. In case deltaFutureBorrow == 0 this case will be interpretted as cna
     * cmbc: deltaFutureBorrow > 0, so round it up.
     * ceccb: deltaFutureBorrow < 0 and deltaFutureBorrow < -futureBorrow. So round it down
     *
     *
     * Dividend and divider roundings:
     * cmcb, ceccb - deltaFutureBorrow < 0 and rounding down. dividend > 0, divider < 0, round dividend up, round divider up
     * cebc - deltaFutureBorrow > 0 and rounding down. So dividend < 0, divider < 0, round dividend up, round divider down
     * cmbc, cecbc - deltaFutureBorrow > 0 and rounding up. So dividend < 0, divider < 0, round dividend down, round divider up
     * cecb - deltaFutureBorrow < 0 and rounding up. So dividend > 0, divider < 0, round dividend down, round divider down
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

    /**
     * @notice Main function to calculate delta future borrow based on delta shares and delta real borrow
     * @dev This is the primary entry point that determines which calculation branch to use
     *      based on the current future borrow state (positive, negative, or zero).
     *      It implements the complete math model from the LTV protocol paper.
     * @param data The input data containing all necessary parameters for the calculation
     * @return deltaFutureBorrow The calculated delta future borrow value
     * @return cases The case configuration that produced the result
     */
    function calculateDeltaFutureBorrowByDeltaSharesAndDeltaRealBorrow(DeltaSharesAndDeltaRealBorrowData memory data)
        external
        pure
        returns (int256, Cases memory)
    {
        if (data.futureBorrow > 0 || data.futureCollateral > 0) {
            return positiveBranchDeltaSharesAndDeltaRealBorrow(data);
        } else if (data.futureBorrow < 0 || data.futureCollateral < 0) {
            return negativeBranchDeltaSharesAndDeltaRealBorrow(data);
        } else {
            return zeroBranchDeltaSharesAndDeltaRealBorrow(data);
        }
    }
}
