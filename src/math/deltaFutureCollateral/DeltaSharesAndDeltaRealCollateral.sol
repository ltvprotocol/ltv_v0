// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../structs/data/vault/DeltaSharesAndDeltaRealCollateralData.sol";
import "../../structs/data/vault/Cases.sol";
import "../../Constants.sol";
import "src/math/CasesOperator.sol";
import "../../utils/MulDiv.sol";
import "src/errors/IVaultErrors.sol";

library DeltaSharesAndDeltaRealCollateral {
    // TODO: make correct round here
    // Up and Down

    using uMulDiv for uint256;
    using sMulDiv for int256;

    struct DividendData {
        Cases cases;
        int256 borrow;
        int256 deltaRealCollateral;
        int256 userFutureRewardCollateral;
        int256 futureCollateral;
        uint256 collateralSlippage;
        int256 protocolFutureRewardBorrow;
        int256 protocolFutureRewardCollateral;
        int256 deltaShares;
        int256 collateral;
        uint16 targetLTVDividend;
        uint16 targetLTVDivider;
    }

    struct DividerData {
        Cases cases;
        uint16 targetLTVDividend;
        uint16 targetLTVDivider;
        int256 userFutureRewardCollateral;
        int256 futureCollateral;
        uint256 collateralSlippage;
        int256 protocolFutureRewardBorrow;
        int256 protocolFutureRewardCollateral;
    }

    function calculateDividentByDeltaSharesAndRealCollateral(DividendData memory data) private pure returns (int256) {
        // borrow
        // (1 - targetLTV) x deltaRealCollateral
        // (1 - targetLTV) x ceccb x -userFutureRewardCollateral
        // (1 - targetLTV) x cecbc x -futureCollateral x collateralSlippage
        // cecbc x - protocolFutureRewardBorrow
        // -shares
        // -targetLTV x collateral
        // targetLTV x ceccb x protocolFutureRewardCollateral

        bool needToRoundUp = (data.cases.cmcb + data.cases.ceccb + data.cases.cebc != 0);

        int256 dividend = int256(data.borrow);
        dividend -= int256(int8(data.cases.cecbc)) * data.protocolFutureRewardBorrow;
        dividend -= data.deltaShares;

        int256 dividendWithTargetLTV = -int256(data.collateral);
        dividendWithTargetLTV += int256(int8(data.cases.ceccb)) * data.protocolFutureRewardCollateral;

        int256 dividendWithOneMinusTargetLTV = data.deltaRealCollateral;
        dividendWithOneMinusTargetLTV -= int256(int8(data.cases.ceccb)) * int256(data.userFutureRewardCollateral);

        dividendWithOneMinusTargetLTV += int256(int8(data.cases.cecbc))
            * (-data.futureCollateral).mulDiv(int256(data.collateralSlippage), Constants.SLIPPAGE_PRECISION, needToRoundUp);

        dividend += dividendWithOneMinusTargetLTV.mulDiv(
            int256(uint256(data.targetLTVDivider) - uint256(data.targetLTVDividend)),
            int256(uint256(data.targetLTVDivider)),
            needToRoundUp
        );
        dividend += dividendWithTargetLTV.mulDiv(
            int256(uint256(data.targetLTVDividend)), int256(uint256(data.targetLTVDivider)), needToRoundUp
        );

        return dividend;
    }

    // divider is always negative
    function calculateDividerByDeltaSharesAndDeltaRealCollateral(DividerData memory data)
        private
        pure
        returns (int256)
    {
        // (1 - targetLTV) x -1
        // (1 - targetLTV) x cecb x (userFutureRewardCollateral / futureCollateral) x -1
        // (1 - targetLTV) x cmbc x collateralSlippage
        // (1 - targetLTV) x cecbc x collateralSlippage
        // cebc x (protocolFutureRewardBorrow / futureCollateral) x -1
        // targetLTV x cecb x (protocolFutureRewardCollateral / futureCollateral)

        bool needToRoundUp = (data.cases.cebc + data.cases.cecb == 0);

        int256 DIVIDER = 10 ** 18;

        int256 dividerWithOneMinusTargetLTV = -DIVIDER;
        int256 divider;
        if (data.futureCollateral != 0) {
            dividerWithOneMinusTargetLTV += int256(int8(data.cases.cecb))
                * (-data.userFutureRewardCollateral).mulDiv(DIVIDER, data.futureCollateral, needToRoundUp);

            divider += int256(int8(data.cases.cebc))
                * (-data.protocolFutureRewardBorrow).mulDiv(DIVIDER, data.futureCollateral, needToRoundUp);

            divider += int256(int8(data.cases.cecb))
                * (data.protocolFutureRewardCollateral).mulDiv(
                    (DIVIDER * int256(uint256(data.targetLTVDividend))),
                    (data.futureCollateral * int256(uint256(data.targetLTVDivider))),
                    needToRoundUp
                );
        }

        dividerWithOneMinusTargetLTV += int256(int8(data.cases.cecbc)) * int256(data.collateralSlippage);
        dividerWithOneMinusTargetLTV += int256(int8(data.cases.cmbc)) * int256(data.collateralSlippage);

        divider += dividerWithOneMinusTargetLTV.mulDiv(
            int256(uint256(data.targetLTVDivider - data.targetLTVDividend)),
            int256(uint256(data.targetLTVDivider)),
            needToRoundUp
        );

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
        int256 deltaFutureCollateral = 0;

        while (true) {
            int256 dividend = calculateDividentByDeltaSharesAndRealCollateral(
                DividendData({
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
                    targetLTVDividend: data.targetLTVDividend,
                    targetLTVDivider: data.targetLTVDivider
                })
            );

            int256 divider = calculateDividerByDeltaSharesAndDeltaRealCollateral(
                DividerData({
                    cases: data.cases,
                    targetLTVDividend: data.targetLTVDividend,
                    targetLTVDivider: data.targetLTVDivider,
                    userFutureRewardCollateral: data.userFutureRewardCollateral,
                    futureCollateral: data.futureCollateral,
                    collateralSlippage: data.collateralSlippage,
                    protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                    protocolFutureRewardCollateral: data.protocolFutureRewardCollateral
                })
            );

            if (dividend == 0 && data.cases.cecb + data.cases.cebc != 0) {
                return (0, CasesOperator.generateCase(6));
            }

            int256 DIVIDER = 10 ** 18;

            if (divider == 0) {
                if (data.cases.ncase >= 5) {
                    revert IVaultErrors.DeltaSharesAndDeltaRealCollateralUnexpectedError(data);
                }
                data.cases = CasesOperator.generateCase(data.cases.ncase + 1);
                continue;
            }

            bool needToRoundUp = (data.cases.cmcb + data.cases.ceccb + data.cases.cebc == 0);
            deltaFutureCollateral = dividend.mulDiv(DIVIDER, divider, needToRoundUp);

            bool validity =
                CasesOperator.checkCaseDeltaFutureCollateral(data.cases, data.futureCollateral, deltaFutureCollateral);

            if (validity) {
                break;
            }

            if (data.cases.ncase == 5) {
                revert IVaultErrors.DeltaSharesAndDeltaRealCollateralUnexpectedError(data);
            }
            data.cases = CasesOperator.generateCase(data.cases.ncase + 1);
        }

        return (deltaFutureCollateral, data.cases);
    }
}
