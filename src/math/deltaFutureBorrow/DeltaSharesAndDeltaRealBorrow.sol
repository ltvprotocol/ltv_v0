// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../structs/data/vault/DeltaSharesAndDeltaRealBorrowData.sol";
import "../../structs/data/vault/Cases.sol";
import "../../Constants.sol";
import "../../utils/MulDiv.sol";
import "src/math/CasesOperator.sol";
import "src/errors/IVaultErrors.sol";

library DeltaSharesAndDeltaRealBorrow {
    using uMulDiv for uint256;
    using sMulDiv for int256;

    struct DividendData {
        int256 borrow;
        int256 collateral;
        int256 protocolFutureRewardBorrow;
        int256 protocolFutureRewardCollateral;
        int256 userFutureRewardBorrow;
        int256 futureBorrow;
        uint256 borrowSlippage;
        int256 deltaRealBorrow;
        int256 deltaShares;
        uint16 targetLTVDividend;
        uint16 targetLTVDivider;
        Cases cases;
    }

    struct DividerData {
        uint16 targetLTVDividend;
        uint16 targetLTVDivider;
        int256 userFutureRewardBorrow;
        int256 futureBorrow;
        uint256 borrowSlippage;
        int256 protocolFutureRewardBorrow;
        int256 protocolFutureRewardCollateral;
        Cases cases;
    }

    function calculateDividentByDeltaSharesAndDeltaRealBorrow(DividendData memory data) private pure returns (int256) {
        // borrow
        // (1 - targetLTV) x deltaRealBorrow
        // (1 - targetLTV) x cecbc x -userFutureRewardBorrow
        // (1 - targetLTV) x ceccb x -futureBorrow x borrowSlippage
        // cecbc x - protocolFutureRewardBorrow
        // -targetLTV x collateral
        // -targetLTV x \Delta shares
        // -targetLTV x ceccb x - protocolFutureRewardCollateral

        bool needToRoundUp = (data.cases.cmcb + data.cases.ceccb + data.cases.cebc != 0);
        int256 dividend = int256(data.borrow);
        dividend -= int256(int8(data.cases.cecbc)) * data.protocolFutureRewardBorrow;

        int256 dividendWithOneMinusTargetLTV = data.deltaRealBorrow;
        dividendWithOneMinusTargetLTV -= int256(int8(data.cases.cecbc)) * int256(data.userFutureRewardBorrow);
        dividendWithOneMinusTargetLTV += int256(int8(data.cases.ceccb))
            * int256(-data.futureBorrow).mulDiv(int256(data.borrowSlippage), Constants.SLIPPAGE_PRECISION, needToRoundUp);

        int256 dividendWithTargetLTV = -int256(data.collateral);
        dividendWithTargetLTV -= data.deltaShares;
        dividendWithTargetLTV += int256(int8(data.cases.ceccb)) * data.protocolFutureRewardCollateral;

        dividend += dividendWithOneMinusTargetLTV.mulDiv(
            int256(uint256(data.targetLTVDivider - data.targetLTVDividend)),
            int256(uint256(data.targetLTVDivider)),
            needToRoundUp
        );
        dividend += dividendWithTargetLTV.mulDiv(
            int256(uint256(data.targetLTVDividend)), int256(uint256(data.targetLTVDivider)), needToRoundUp
        );

        return dividend;
    }

    // divider always < 0
    function calculateDividerByDeltaSharesAndDeltaRealBorrow(DividerData memory data) private pure returns (int256) {
        // (1 - targetLTV) x -1
        // (1 - targetLTV) x cebc x -(userFutureRewardBorrow / futureBorrow)
        // (1 - targetLTV) x cmcb x borrowSlippage
        // (1 - targetLTV) x ceccb x borrowSlippage
        // cebc x -(protocolFutureRewardBorrow / futureBorrow)
        // -targetLTV x cecb x -(protocolFutureRewardCollateral / futureBorrow)

        bool needToRoundUp = (data.cases.cebc + data.cases.cecb == 0);
        int256 DIVIDER = 10 ** 18;

        int256 dividerWithOneMinusTargetLTV = -DIVIDER;
        int256 divider;

        if (data.futureBorrow != 0) {
            dividerWithOneMinusTargetLTV += int256(int8(data.cases.cebc))
                * (-data.userFutureRewardBorrow).mulDiv(DIVIDER, data.futureBorrow, needToRoundUp);

            divider += int256(int8(data.cases.cebc))
                * (-data.protocolFutureRewardBorrow).mulDiv(DIVIDER, data.futureBorrow, needToRoundUp);

            divider += int256(int8(data.cases.cecb))
                * data.protocolFutureRewardCollateral.mulDiv(
                    (DIVIDER * int256(uint256(data.targetLTVDividend))),
                    (data.futureBorrow * int256(uint256(data.targetLTVDivider))),
                    needToRoundUp
                );
        }

        dividerWithOneMinusTargetLTV += int256(int8(data.cases.ceccb)) * int256(data.borrowSlippage);
        dividerWithOneMinusTargetLTV += int256(int8(data.cases.cmcb)) * int256(data.borrowSlippage);
        divider += dividerWithOneMinusTargetLTV.mulDiv(
            int256(uint256(data.targetLTVDivider - data.targetLTVDividend)),
            int256(uint256(data.targetLTVDivider)),
            needToRoundUp
        );

        return divider;
    }

    /**
     *
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
    function calculateDeltaFutureBorrowByDeltaSharesAndDeltaRealBorrow(DeltaSharesAndDeltaRealBorrowData memory data)
        external
        pure
        returns (int256, Cases memory)
    {
        int256 deltaFutureBorrow = 0;

        while (true) {
            int256 dividend = calculateDividentByDeltaSharesAndDeltaRealBorrow(
                DividendData({
                    borrow: data.borrow,
                    collateral: data.collateral,
                    protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                    protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                    userFutureRewardBorrow: data.userFutureRewardBorrow,
                    futureBorrow: data.futureBorrow,
                    borrowSlippage: data.borrowSlippage,
                    deltaRealBorrow: data.deltaRealBorrow,
                    deltaShares: data.deltaShares,
                    targetLTVDividend: data.targetLTVDividend,
                    targetLTVDivider: data.targetLTVDivider,
                    cases: data.cases
                })
            );

            if (dividend == 0 && data.cases.cecb + data.cases.cebc != 0) {
                return (0, CasesOperator.generateCase(6));
            }

            int256 divider = calculateDividerByDeltaSharesAndDeltaRealBorrow(
                DividerData({
                    targetLTVDividend: data.targetLTVDividend,
                    targetLTVDivider: data.targetLTVDivider,
                    userFutureRewardBorrow: data.userFutureRewardBorrow,
                    futureBorrow: data.futureBorrow,
                    borrowSlippage: data.borrowSlippage,
                    protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                    protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                    cases: data.cases
                })
            );

            int256 DIVIDER = 10 ** 18;

            if (divider == 0) {
                if (data.cases.ncase >= 5) {
                    revert IVaultErrors.DeltaSharesAndDeltaRealBorrowUnexpectedError(data);
                }
                data.cases = CasesOperator.generateCase(data.cases.ncase + 1);
                continue;
            }
            bool needToRoundUp = (data.cases.cmcb + data.cases.ceccb + data.cases.cebc == 0);
            deltaFutureBorrow = dividend.mulDiv(DIVIDER, divider, needToRoundUp);

            bool validity = CasesOperator.checkCaseDeltaFutureBorrow(data.cases, data.futureBorrow, deltaFutureBorrow);

            if (validity) {
                break;
            }

            if (data.cases.ncase == 5) {
                revert IVaultErrors.DeltaSharesAndDeltaRealBorrowUnexpectedError(data);
            }

            data.cases = CasesOperator.generateCase(data.cases.ncase + 1);
        }

        return (deltaFutureBorrow, data.cases);
    }
}
