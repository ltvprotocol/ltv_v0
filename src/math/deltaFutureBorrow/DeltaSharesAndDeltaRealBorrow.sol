// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../Structs.sol";
import "../../Constants.sol";
import "../../Cases.sol";
import "../../utils/MulDiv.sol";


library DeltaSharesAndDeltaRealBorrow {

    using uMulDiv for uint256;
    using sMulDiv for int256;

    error DeltaSharesAndDeltaRealBorrowUnexpectedError(ConvertedAssets convertedAssets, Prices prices, int256 deltaRealBorrow, int256 deltaShares);

    function calculateDividentByDeltaSharesAndDeltaRealBorrow(
        Cases memory cases,
        Prices memory prices, 
        ConvertedAssets memory convertedAssets,
        int256 deltaRealBorrow,
        int256 deltaShares,
        uint128 targetLTV
    ) private pure returns (int256) {
        // borrow
        // (1 - targetLTV) x deltaRealBorrow
        // (1 - targetLTV) x cecbc x -userFutureRewardBorrow
        // (1 - targetLTV) x ceccb x -futureBorrow x borrowSlippage
        // cecbc x - protocolFutureRewardBorrow
        // -targetLTV x collateral
        // -targetLTV x \Delta shares
        // -targetLTV x ceccb x - protocolFutureRewardCollateral

        int256 dividend = int256(convertedAssets.borrow);
        dividend -= int256(int8(cases.cecbc)) * convertedAssets.protocolFutureRewardBorrow;

        int256 dividendWithOneMinusTargetLTV = deltaRealBorrow;
        dividendWithOneMinusTargetLTV -= int256(int8(cases.cecbc)) * int256(convertedAssets.userFutureRewardBorrow);
        // goes to dividend with sign minus, so needs to be rounded up
        dividendWithOneMinusTargetLTV -= int256(int8(cases.ceccb)) * int256(convertedAssets.futureBorrow).mulDivUp(int256(prices.borrowSlippage), Constants.SLIPPAGE_PRECISION);

        int256 dividendWithTargetLTV = -int256(convertedAssets.collateral);
        dividendWithTargetLTV -= deltaShares;
        dividendWithTargetLTV += int256(int8(cases.ceccb)) * convertedAssets.protocolFutureRewardCollateral;
        
        //goes to dividend with sign plus, so needs to be rounded down
        dividend += dividendWithOneMinusTargetLTV.mulDivDown(int256(Constants.LTV_DIVIDER - targetLTV), int256(Constants.LTV_DIVIDER));
        //goes to dividend with sign plus, so needs to be rounded down
        dividend += dividendWithTargetLTV.mulDivDown(int128(targetLTV), int256(Constants.LTV_DIVIDER));

        return dividend;
    }

    // divider always < 0
    function calculateDividerByDeltaSharesAndDeltaRealBorrow(
        Cases memory cases,
        Prices memory prices, 
        ConvertedAssets memory convertedAssets,
        uint128 targetLTV
        //int256 deltaRealBorrow,
        //int256 deltaShares
    ) private pure returns (int256) {
        // (1 - targetLTV) x -1
        // (1 - targetLTV) x cebc x -(userFutureRewardBorrow / futureBorrow)
        // (1 - targetLTV) x cmcb x borrowSlippage
        // (1 - targetLTV) x ceccb x borrowSlippage
        // cebc x -(protocolFutureRewardBorrow / futureBorrow)
        // -targetLTV x cecb x -(protocolFutureRewardCollateral / futureBorrow)
        
        int256 DIVIDER = 10**18;

        int256 dividerWithOneMinusTargetLTV = -DIVIDER;
        int256 divider;

        if (convertedAssets.futureBorrow != 0) {
            // in cebc case divider need to be rounded up, it goes to divider with sign minus, so needs to be rounded down. Same for next
            dividerWithOneMinusTargetLTV -= int256(int8(cases.cebc)) * convertedAssets.userFutureRewardBorrow.mulDivDown(DIVIDER, convertedAssets.futureBorrow);
            divider -= int256(int8(cases.cebc)) * convertedAssets.protocolFutureRewardBorrow.mulDivDown(DIVIDER, convertedAssets.futureBorrow);
            // in cecb case divider needs to be rounded down, since it goes to divider with sign plus, needs to be rounded down
            divider += int256(int8(cases.cecb)) * convertedAssets.protocolFutureRewardCollateral.mulDivDown((DIVIDER * int128(targetLTV)), (convertedAssets.futureBorrow * int256(Constants.LTV_DIVIDER)));
        }

        dividerWithOneMinusTargetLTV += int256(int8(cases.ceccb)) * int256(prices.borrowSlippage);
        dividerWithOneMinusTargetLTV += int256(int8(cases.cmcb)) * int256(prices.borrowSlippage);
        if (cases.cmcb + cases.cebc + cases.ceccb != 0) {
            divider += dividerWithOneMinusTargetLTV.mulDivUp(int256(Constants.LTV_DIVIDER - targetLTV), int256(Constants.LTV_DIVIDER));
        } else {
            divider += dividerWithOneMinusTargetLTV.mulDivDown(int256(Constants.LTV_DIVIDER - targetLTV), int256(Constants.LTV_DIVIDER));
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
    function calculateDeltaFutureBorrowByDeltaSharesAndDeltaRealBorrow(
        Prices memory prices,
        ConvertedAssets memory convertedAssets,
        Cases memory cases,
        int256 deltaRealBorrow,
        int256 deltaShares,
        uint128 targetLTV
    ) external pure returns (int256, Cases memory) {

        int256 deltaFutureBorrow = 0;

        while (true) {
            int256 dividend = calculateDividentByDeltaSharesAndDeltaRealBorrow(cases, prices, convertedAssets, deltaRealBorrow, deltaShares, targetLTV);

            int256 divider = calculateDividerByDeltaSharesAndDeltaRealBorrow(cases, prices, convertedAssets, targetLTV);

            int256 DIVIDER = 10**18;

            if (divider == 0) {
                if (cases.ncase >= 6) {
                    revert DeltaSharesAndDeltaRealBorrowUnexpectedError(convertedAssets, prices, deltaRealBorrow, deltaShares);
                }
                cases = CasesOperator.generateCase(cases.ncase + 1);
                continue;
            }
            deltaFutureBorrow = dividend.mulDivUp(DIVIDER, divider);

            bool validity = CasesOperator.checkCaseDeltaFutureBorrow(cases, convertedAssets, deltaFutureBorrow);

            if (validity) {
                break;
            }

            if (cases.ncase == 6) {
                revert DeltaSharesAndDeltaRealBorrowUnexpectedError(convertedAssets, prices, deltaRealBorrow, deltaShares);
            }

            cases = CasesOperator.generateCase(cases.ncase + 1);
        }

        return (deltaFutureBorrow, cases);
    }
}