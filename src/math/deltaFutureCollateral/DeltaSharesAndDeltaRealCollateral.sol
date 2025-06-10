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
        uint128 targetLTV;
    }

    struct DividerData {
        Cases cases;
        uint128 targetLTV;
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

        int256 dividend = int256(data.borrow);
        dividend -= int256(int8(data.cases.cecbc)) * data.protocolFutureRewardBorrow;
        dividend -= data.deltaShares;

        int256 dividendWithTargetLTV = -int256(data.collateral);
        dividendWithTargetLTV += int256(int8(data.cases.ceccb)) * data.protocolFutureRewardCollateral;

        int256 dividendWithOneMinusTargetLTV = data.deltaRealCollateral;
        dividendWithOneMinusTargetLTV -= int256(int8(data.cases.ceccb)) * int256(data.userFutureRewardCollateral);
        // goes to dividend with minus, so needs to be rounded down
        dividendWithOneMinusTargetLTV -= int256(int8(data.cases.cecbc))
            * data.futureCollateral.mulDivDown(int256(data.collateralSlippage), Constants.SLIPPAGE_PRECISION);

        // goes to dividend with plus, so needs to be rounded up
        dividend += dividendWithOneMinusTargetLTV.mulDivUp(
            int256(Constants.LTV_DIVIDER - data.targetLTV), int256(Constants.LTV_DIVIDER)
        );
        // goes to dividend with plus, so needs to be rounded up
        dividend += dividendWithTargetLTV.mulDivUp(int128(data.targetLTV), int256(Constants.LTV_DIVIDER));

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

        int256 DIVIDER = 10 ** 18;

        int256 dividerWithOneMinusTargetLTV = -DIVIDER;
        int256 divider;
        if (data.futureCollateral != 0) {
            // in cecb case divider needs to be rounded up, since it goes to divider with sign minus, needs to be rounded down
            dividerWithOneMinusTargetLTV -= int256(int8(data.cases.cecb))
                * data.userFutureRewardCollateral.mulDivDown(DIVIDER, data.futureCollateral);
            // in cebc case divider nneds to be rounded down, since it goes to divider with sign minus, needs to be rounded up
            divider -=
                int256(int8(data.cases.cebc)) * data.protocolFutureRewardBorrow.mulDivUp(DIVIDER, data.futureCollateral);
            // in cecb case divider needs to be rounded up, since it goes to divider with sign plus, needs to be rounded up
            divider += int256(int8(data.cases.cecb))
                * data.protocolFutureRewardCollateral.mulDivUp(
                    (DIVIDER * int128(data.targetLTV)), (data.futureCollateral * int256(Constants.LTV_DIVIDER))
                );
        }

        dividerWithOneMinusTargetLTV += int256(int8(data.cases.cecbc)) * int256(data.collateralSlippage);
        dividerWithOneMinusTargetLTV += int256(int8(data.cases.cmbc)) * int256(data.collateralSlippage);

        if (data.cases.cmcb + data.cases.cecbc + data.cases.ceccb != 0) {
            divider += dividerWithOneMinusTargetLTV.mulDivDown(
                int256(Constants.LTV_DIVIDER - data.targetLTV), int256(Constants.LTV_DIVIDER)
            );
        } else {
            divider += dividerWithOneMinusTargetLTV.mulDivUp(
                int256(Constants.LTV_DIVIDER - data.targetLTV), int256(Constants.LTV_DIVIDER)
            );
        }

        return divider;
    }

    // These functions are used in Deposit/withdraw/mint/redeem. Since this math implies that deltaTotalAssets = deltaTotalShares, we don't have
    // HODLer conflict here. So the only conflict is between depositor/withdrawer and future executor. For future executor it's better to have bigger
    // futureBorrow, so we need always round delta future borrow to the top
    // cna - dividend is 0
    // cmcb, cebc, ceccb - deltaFutureCollateral is positive, so dividend is negative, dividend needs to be rounded up, divider needs to be rounded down
    // cmbc, cecb, cecbc - deltaFutureCollateral is negative, so dividend is positive, dividend needs to be rounded up, divider needs to be rounded up
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
                    targetLTV: data.targetLTV
                })
            );

            int256 divider = calculateDividerByDeltaSharesAndDeltaRealCollateral(
                DividerData({
                    cases: data.cases,
                    targetLTV: data.targetLTV,
                    userFutureRewardCollateral: data.userFutureRewardCollateral,
                    futureCollateral: data.futureCollateral,
                    collateralSlippage: data.collateralSlippage,
                    protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                    protocolFutureRewardCollateral: data.protocolFutureRewardCollateral
                })
            );

            int256 DIVIDER = 10 ** 18;

            if (divider == 0) {
                if (data.cases.ncase >= 6) {
                    revert IVaultErrors.DeltaSharesAndDeltaRealCollateralUnexpectedError(data);
                }
                data.cases = CasesOperator.generateCase(data.cases.ncase + 1);
                continue;
            }
            // up because it's better for protocol
            deltaFutureCollateral = dividend.mulDivDown(DIVIDER, divider);

            bool validity =
                CasesOperator.checkCaseDeltaFutureCollateral(data.cases, data.futureCollateral, deltaFutureCollateral);

            if (validity) {
                break;
            }

            if (data.cases.ncase == 6) {
                revert IVaultErrors.DeltaSharesAndDeltaRealCollateralUnexpectedError(data);
            }
            data.cases = CasesOperator.generateCase(data.cases.ncase + 1);
        }

        return (deltaFutureCollateral, data.cases);
    }
}
