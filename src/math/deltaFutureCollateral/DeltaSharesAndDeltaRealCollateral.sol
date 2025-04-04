// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../Structs.sol";
import "../../Constants.sol";
import "../../Cases.sol";
import "../../utils/MulDiv.sol";
import '../../State.sol';

library DeltaSharesAndDeltaRealCollateral {

    // TODO: make correct round here
    // Up and Down

    using uMulDiv for uint256;
    using sMulDiv for int256;

    error DeltaSharesAndDeltaRealCollateralUnexpectedError(ConvertedAssets convertedAssets, Prices prices, int256 deltaRealCollateral, int256 deltaShares);
    
    
    function calculateDividentByDeltaSharesAndRealCollateral(
        Cases memory cases,
        Prices memory prices, 
        ConvertedAssets memory convertedAssets,
        int256 deltaRealCollateral,
        int256 deltaShares,
        uint128 targetLTV
    ) private pure returns (int256) {
        // borrow
        // (1 - targetLTV) x deltaRealCollateral
        // (1 - targetLTV) x ceccb x -userFutureRewardCollateral
        // (1 - targetLTV) x cecbc x -futureCollateral x collateralSlippage
        // cecbc x - protocolFutureRewardBorrow
        // -shares
        // -targetLTV x collateral
        // targetLTV x ceccb x protocolFutureRewardCollateral

        int256 dividend = int256(convertedAssets.borrow);
        dividend -= int256(int8(cases.cecbc)) * convertedAssets.protocolFutureRewardBorrow;
        dividend -= deltaShares;

        int256 dividendWithTargetLTV = -int256(convertedAssets.collateral);
        dividendWithTargetLTV += int256(int8(cases.ceccb)) * convertedAssets.protocolFutureRewardCollateral;

        int256 dividendWithOneMinusTargetLTV = deltaRealCollateral;
        dividendWithOneMinusTargetLTV -= int256(int8(cases.ceccb)) * int256(convertedAssets.userFutureRewardCollateral);
        // goes to dividend with minus, so needs to be rounded down
        dividendWithOneMinusTargetLTV -= int256(int8(cases.cecbc)) * convertedAssets.futureCollateral.mulDivDown(int256(prices.collateralSlippage), Constants.SLIPPAGE_PRECISION);


        // goes to dividend with plus, so needs to be rounded up
        dividend += dividendWithOneMinusTargetLTV.mulDivUp(int256(Constants.LTV_DIVIDER - targetLTV), int256(Constants.LTV_DIVIDER));
        // goes to dividend with plus, so needs to be rounded up
        dividend += dividendWithTargetLTV.mulDivUp(int128(targetLTV), int256(Constants.LTV_DIVIDER));

        return dividend;
    }

    // divider is always negative
    function calculateDividerByDeltaSharesAndDeltaRealCollateral(
        Cases memory cases,
        Prices memory prices, 
        ConvertedAssets memory convertedAssets,
        uint128 targetLTV
        //int256 deltaRealCollateral,
        //int256 deltaShares
    ) private pure returns (int256) {
        // (1 - targetLTV) x -1
        // (1 - targetLTV) x cecb x (userFutureRewardCollateral / futureCollateral) x -1
        // (1 - targetLTV) x cmbc x collateralSlippage
        // (1 - targetLTV) x cecbc x collateralSlippage
        // cebc x (protocolFutureRewardBorrow / futureCollateral) x -1
        // targetLTV x cecb x (protocolFutureRewardCollateral / futureCollateral)
        
        int256 DIVIDER = 10**18;

        int256 dividerWithOneMinusTargetLTV = -DIVIDER;
        int256 divider; 
        if (convertedAssets.futureCollateral != 0) {
            // in cecb case divider needs to be rounded up, since it goes to divider with sign minus, needs to be rounded down
            dividerWithOneMinusTargetLTV -= int256(int8(cases.cecb)) * convertedAssets.userFutureRewardCollateral.mulDivDown(DIVIDER, convertedAssets.futureCollateral);
            dividerWithOneMinusTargetLTV += int256(int8(cases.cecbc)) * int256(prices.collateralSlippage);
            // in cebc case divider nneds to be rounded down, since it goes to divider with sign minus, needs to be rounded up
            divider -= int256(int8(cases.cebc)) * convertedAssets.protocolFutureRewardBorrow.mulDivUp(DIVIDER, convertedAssets.futureCollateral);
            // in cecb case divider needs to be rounded up, since it goes to divider with sign plus, needs to be rounded up
            divider += int256(int8(cases.cecb)) * convertedAssets.protocolFutureRewardCollateral.mulDivUp((DIVIDER * int128(targetLTV)), (convertedAssets.futureCollateral * int256(Constants.LTV_DIVIDER)));
        }
        dividerWithOneMinusTargetLTV += int256(int8(cases.cmbc)) * int256(prices.collateralSlippage);
        
        if (cases.cmcb + cases.cecbc + cases.ceccb != 0) {
            divider += dividerWithOneMinusTargetLTV.mulDivDown(int256(Constants.LTV_DIVIDER - targetLTV), int256(Constants.LTV_DIVIDER));
        } else {
            divider += dividerWithOneMinusTargetLTV.mulDivUp(int256(Constants.LTV_DIVIDER - targetLTV), int256(Constants.LTV_DIVIDER));
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
        Prices memory prices, 
        ConvertedAssets memory convertedAssets,
        Cases memory cases,
        int256 deltaRealCollateral,
        int256 deltaShares,
        uint128 targetLTV
    ) external pure returns (int256, Cases memory) {

        int256 deltaFutureCollateral = 0;

        while (true) {

            int256 dividend = calculateDividentByDeltaSharesAndRealCollateral(cases, prices, convertedAssets, deltaRealCollateral, deltaShares, targetLTV);

            int256 divider = calculateDividerByDeltaSharesAndDeltaRealCollateral(cases, prices, convertedAssets, targetLTV);

            int256 DIVIDER = 10**18;

            if (divider == 0) {
                if (cases.ncase >= 6) {
                    revert DeltaSharesAndDeltaRealCollateralUnexpectedError(convertedAssets, prices, deltaRealCollateral, deltaShares);
                }
                cases = CasesOperator.generateCase(cases.ncase + 1);
                continue;
            }
            // up because it's better for protocol
            deltaFutureCollateral = dividend.mulDivDown(DIVIDER, divider);

            bool validity = CasesOperator.checkCaseDeltaFutureCollateral(cases, convertedAssets, deltaFutureCollateral);

            if (validity) {
                break;
            }

            if (cases.ncase == 6) {
                revert DeltaSharesAndDeltaRealCollateralUnexpectedError(convertedAssets, prices, deltaRealCollateral, deltaShares);
            }
            cases = CasesOperator.generateCase(cases.ncase + 1);
        }

        return (deltaFutureCollateral, cases);
    }
}