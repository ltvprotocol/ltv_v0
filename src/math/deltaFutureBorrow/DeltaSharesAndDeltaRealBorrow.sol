// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../../Structs.sol";
import "../../Constants.sol";
import "../../Cases.sol";
import "../../utils/MulDiv.sol";
import '../../State.sol';

abstract contract DeltaSharesAndDeltaRealBorrow is State {

    using uMulDiv for uint256;
    using sMulDiv for int256;

    function calculateDividentByDeltaSharesAndDeltaRealBorrow(
        Cases memory cases,
        Prices memory prices, 
        ConvertedAssets memory convertedAssets,
        int256 deltaRealBorrow,
        int256 deltaShares
    ) public view returns (int256) {
        // borrow
        // (1 - targetLTV) x deltaRealBorrow
        // (1 - targetLTV) x cecbc x -userFutureRewardBorrow
        // (1 - targetLTV) x ceccb x -futureBorrow x borrowSlippage
        // cecbc x - protocolFutureRewardBorrow
        // -targetLTV x collateral
        // -targetLTV x \Delta shares
        // -targetLTV x \Delta ceccb x - protocolFutureRewardCollateral

        int256 DIVIDER = 10**18;

        int256 dividend = -int256(convertedAssets.borrow);
        dividend -= int256(int8(cases.cecbc)) * convertedAssets.protocolFutureRewardBorrow;

        int256 dividendWithOneMinusTargetLTV = deltaRealBorrow;
        dividendWithOneMinusTargetLTV -= int256(int8(cases.cecbc)) * int256(convertedAssets.userFutureRewardBorrow);
        dividendWithOneMinusTargetLTV -= int256(int8(cases.ceccb)) * int256(convertedAssets.futureBorrow).mulDivUp(int256(prices.borrowSlippage), DIVIDER);

        int256 dividendWithTargetLTV = -int256(convertedAssets.collateral);
        dividendWithTargetLTV -= int256(int8(cases.ceccb)) * deltaShares;
        dividendWithTargetLTV -= int256(int8(cases.ceccb)) * convertedAssets.protocolFutureRewardCollateral;

        dividend += dividendWithOneMinusTargetLTV.mulDivDown(int256(Constants.LTV_DIVIDER - targetLTV), int256(Constants.LTV_DIVIDER));
        dividend += dividendWithTargetLTV.mulDivDown(int128(targetLTV), int256(Constants.LTV_DIVIDER));

        return dividend;
    }

    function calculateDividerByDeltaSharesAndDeltaRealBorrow(
        Cases memory cases,
        Prices memory prices, 
        ConvertedAssets memory convertedAssets
        //int256 deltaRealBorrow,
        //int256 deltaShares
    ) public view returns (int256) {
        // (1 - targetLTV) x -1
        // (1 - targetLTV) x cebc x (userFutureRewardBorrow / futureBorrow)
        // (1 - targetLTV) x cmcb x borrowSlippage
        // (1 - targetLTV) x ceccb x borrowSlippage
        // cebc x (protocolFutureRewardBorrow / futureBorrow)
        // -targetLTV x cecb x (protocolFutureRewardCollateral / futureBorrow)
        
        int256 DIVIDER = 10**18;

        int256 dividerWithOneMinusTargetLTV = -DIVIDER;
        int256 divider;

        if (convertedAssets.futureBorrow != 0) {
            dividerWithOneMinusTargetLTV = -int256(int8(cases.cebc)) * convertedAssets.userFutureRewardBorrow.mulDivDown(DIVIDER, convertedAssets.futureBorrow);
            dividerWithOneMinusTargetLTV = -int256(int8(cases.ceccb)) * int256(prices.borrowSlippage);
            divider += -int256(int8(cases.cebc)) * convertedAssets.protocolFutureRewardBorrow.mulDivDown(DIVIDER, convertedAssets.futureBorrow);
            divider = int256(int8(cases.cecb)) * convertedAssets.protocolFutureRewardCollateral.mulDivUp((DIVIDER * int128(targetLTV)), (convertedAssets.futureBorrow * int256(Constants.LTV_DIVIDER)));
        }

        dividerWithOneMinusTargetLTV = -int256(int8(cases.cmcb)) * int256(prices.borrowSlippage);
        divider += dividerWithOneMinusTargetLTV.mulDivUp(int256(Constants.LTV_DIVIDER - targetLTV), int256(Constants.LTV_DIVIDER));

        return divider;
    }

    function calculateDeltaFutureBorrowByDeltaSharesAndDeltaRealBorrow(
        Prices memory prices,
        ConvertedAssets memory convertedAssets,
        Cases memory cases,
        int256 deltaRealBorrow,
        int256 deltaShares
    ) public view returns (int256, Cases memory) {

        // ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        // Prices memory prices = getPrices();
        int256 deltaFutureBorrow = 0;

        while (true) {
            int256 dividend = calculateDividentByDeltaSharesAndDeltaRealBorrow(cases, prices, convertedAssets, deltaRealBorrow, deltaShares);

            int256 divider = calculateDividerByDeltaSharesAndDeltaRealBorrow(cases, prices, convertedAssets);

            int256 DIVIDER = 10**18;

            if (divider == 0) {
                cases = CasesOperator.generateCase(cases.ncase + 1);
                continue;
            }
            deltaFutureBorrow = dividend.mulDivDown(DIVIDER, divider);

            bool validity = CasesOperator.checkCaseDeltaFutureBorrow(cases, convertedAssets, deltaFutureBorrow);

            if (validity) {
                break;
            }

            if (cases.ncase == 6) {
                // unexpected bihaviour
                return (0, cases);
            }

            cases = CasesOperator.generateCase(cases.ncase + 1);
        }

        return (deltaFutureBorrow, cases);
    }
}