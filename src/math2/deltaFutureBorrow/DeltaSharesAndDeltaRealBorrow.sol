// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../structs/data/vault/DeltaSharesAndDeltaRealBorrowData.sol';
import '../../structs/data/vault/Cases.sol';
import '../../Constants.sol';
import '../../utils/MulDiv.sol';
import 'src/math2/CasesOperator.sol';
import 'src/errors/IVaultErrors.sol';

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
        uint128 targetLTV;
        Cases cases;
    }

    struct DividerData {
        uint128 targetLTV;
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

        int256 dividend = int256(data.borrow);
        dividend -= int256(int8(data.cases.cecbc)) * data.protocolFutureRewardBorrow;

        int256 dividendWithOneMinusTargetLTV = data.deltaRealBorrow;
        dividendWithOneMinusTargetLTV -= int256(int8(data.cases.cecbc)) * int256(data.userFutureRewardBorrow);
        // goes to dividend with sign minus, so needs to be rounded up
        dividendWithOneMinusTargetLTV -=
            int256(int8(data.cases.ceccb)) *
            int256(data.futureBorrow).mulDivUp(int256(data.borrowSlippage), Constants.SLIPPAGE_PRECISION);

        int256 dividendWithTargetLTV = -int256(data.collateral);
        dividendWithTargetLTV -= data.deltaShares;
        dividendWithTargetLTV += int256(int8(data.cases.ceccb)) * data.protocolFutureRewardCollateral;

        //goes to dividend with sign plus, so needs to be rounded down
        dividend += dividendWithOneMinusTargetLTV.mulDivDown(int256(Constants.LTV_DIVIDER - data.targetLTV), int256(Constants.LTV_DIVIDER));
        //goes to dividend with sign plus, so needs to be rounded down
        dividend += dividendWithTargetLTV.mulDivDown(int128(data.targetLTV), int256(Constants.LTV_DIVIDER));

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

        int256 DIVIDER = 10 ** 18;

        int256 dividerWithOneMinusTargetLTV = -DIVIDER;
        int256 divider;

        if (data.futureBorrow != 0) {
            // in cebc case divider need to be rounded up, it goes to divider with sign minus, so needs to be rounded down. Same for next
            dividerWithOneMinusTargetLTV -=
                int256(int8(data.cases.cebc)) *
                data.userFutureRewardBorrow.mulDivDown(DIVIDER, data.futureBorrow);
            divider -= int256(int8(data.cases.cebc)) * data.protocolFutureRewardBorrow.mulDivDown(DIVIDER, data.futureBorrow);
            // in cecb case divider needs to be rounded down, since it goes to divider with sign plus, needs to be rounded down
            divider +=
                int256(int8(data.cases.cecb)) *
                data.protocolFutureRewardCollateral.mulDivDown(
                    (DIVIDER * int128(data.targetLTV)),
                    (data.futureBorrow * int256(Constants.LTV_DIVIDER))
                );
        }

        dividerWithOneMinusTargetLTV += int256(int8(data.cases.ceccb)) * int256(data.borrowSlippage);
        dividerWithOneMinusTargetLTV += int256(int8(data.cases.cmcb)) * int256(data.borrowSlippage);
        if (data.cases.cmcb + data.cases.cebc + data.cases.ceccb != 0) {
            divider += dividerWithOneMinusTargetLTV.mulDivUp(int256(Constants.LTV_DIVIDER - data.targetLTV), int256(Constants.LTV_DIVIDER));
        } else {
            divider += dividerWithOneMinusTargetLTV.mulDivDown(int256(Constants.LTV_DIVIDER - data.targetLTV), int256(Constants.LTV_DIVIDER));
        }

        return divider;
    }

    // These functions are used in Deposit/withdraw/mint/redeem. Since this math implies that deltaTotalAssets = deltaTotalShares, we don't have
    // HODLer conflict here. So the only conflict is between depositor/withdrawer and future executor. For future executor it's better to have bigger
    // futureBorrow, so we need always round delta future borrow to the top
    // divider is always negative
    // cna - dividend is 0
    // cmcb, cebc, ceccb - deltaFutureBorrow is positive, so dividend is negative, dividend needs to be rounded down, divider needs to be rounded up
    // cmbc, cecb, cecbc - deltaFutureBorrow is negative, so dividend is positive, dividend needs to be rounded down, divider needs to be rounded down
    function calculateDeltaFutureBorrowByDeltaSharesAndDeltaRealBorrow(DeltaSharesAndDeltaRealBorrowData memory data) external pure returns (int256, Cases memory) {
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
                    targetLTV: data.targetLTV,
                    cases: data.cases
                }));

            int256 divider = calculateDividerByDeltaSharesAndDeltaRealBorrow(
                DividerData({
                    targetLTV: data.targetLTV,
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
                if (data.cases.ncase >= 6) {
                    revert IVaultErrors.DeltaSharesAndDeltaRealBorrowUnexpectedError(data);
                }
                data.cases = CasesOperator.generateCase(data.cases.ncase + 1);
                continue;
            }
            deltaFutureBorrow = dividend.mulDivUp(DIVIDER, divider);

            bool validity = CasesOperator.checkCaseDeltaFutureBorrow(data.cases, data.futureBorrow, deltaFutureBorrow);

            if (validity) {
                break;
            }

            if (data.cases.ncase == 6) {
                revert IVaultErrors.    DeltaSharesAndDeltaRealBorrowUnexpectedError(data);
            }

            data.cases = CasesOperator.generateCase(data.cases.ncase + 1);
        }

        return (deltaFutureBorrow, data.cases);
    }
}
