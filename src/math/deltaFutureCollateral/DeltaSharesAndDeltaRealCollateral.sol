// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IVaultErrors} from "src/errors/IVaultErrors.sol";
import {Constants} from "src/Constants.sol";
import {Cases} from "src/structs/data/vault/Cases.sol";
import {
    DeltaSharesAndDeltaRealCollateralData,
    DividendData,
    DividerData
} from "src/structs/data/vault/DeltaSharesAndDeltaRealCollateralData.sol";
import {CasesOperator} from "src/math/CasesOperator.sol";
import {uMulDiv, sMulDiv} from "src/utils/MulDiv.sol";

library DeltaSharesAndDeltaRealCollateral {
    // TODO: make correct round here
    // Up and Down

    using uMulDiv for uint256;
    using sMulDiv for int256;

    function calculateDividentByDeltaSharesAndRealCollateral(DividendData memory data) private pure returns (int256) {
        // borrow
        // (1 - targetLtv) x deltaRealCollateral
        // (1 - targetLtv) x ceccb x -userFutureRewardCollateral
        // (1 - targetLtv) x cecbc x -futureCollateral x collateralSlippage
        // cecbc x - protocolFutureRewardBorrow
        // -shares
        // -targetLtv x collateral
        // targetLtv x ceccb x protocolFutureRewardCollateral

        bool needToRoundUp = (data.cases.cmcb + data.cases.ceccb + data.cases.cebc != 0);

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
    function calculateDividerByDeltaSharesAndDeltaRealCollateral(DividerData memory data)
        private
        pure
        returns (int256)
    {
        // (1 - targetLtv) x -1
        // (1 - targetLtv) x cecb x (userFutureRewardCollateral / futureCollateral) x -1
        // (1 - targetLtv) x cmbc x collateralSlippage
        // (1 - targetLtv) x cecbc x collateralSlippage
        // cebc x (protocolFutureRewardBorrow / futureCollateral) x -1
        // targetLtv x cecb x (protocolFutureRewardCollateral / futureCollateral)

        bool needToRoundUp = (data.cases.cebc + data.cases.cecb == 0);

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
                    targetLtvDividend: data.targetLtvDividend,
                    targetLtvDivider: data.targetLtvDivider
                })
            );

            int256 divider = calculateDividerByDeltaSharesAndDeltaRealCollateral(
                DividerData({
                    cases: data.cases,
                    targetLtvDividend: data.targetLtvDividend,
                    targetLtvDivider: data.targetLtvDivider,
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

            if (divider == 0) {
                if (data.cases.ncase >= 5) {
                    revert IVaultErrors.DeltaSharesAndDeltaRealCollateralUnexpectedError(data);
                }
                data.cases = CasesOperator.generateCase(data.cases.ncase + 1);
                continue;
            }

            bool needToRoundUp = (data.cases.cmcb + data.cases.ceccb + data.cases.cebc == 0);
            deltaFutureCollateral = dividend.mulDiv(Constants.DIVIDER_PRECISION, divider, needToRoundUp);

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
