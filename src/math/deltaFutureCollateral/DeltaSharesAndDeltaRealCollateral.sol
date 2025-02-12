// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../../Structs.sol";
import "../../Constants.sol";
import "../../Cases.sol";
import "../../utils/MulDiv.sol";
import '../../State.sol';

abstract contract DeltaSharesAndDeltaRealCollateral is State {

    // TODO: make correct round here
    // Up and Down

    using uMulDiv for uint256;
    using sMulDiv for int256;

    function calculateDividentByDeltaSharesAndRealCollateral(
        Cases memory cases,
        Prices memory prices, 
        ConvertedAssets memory convertedAssets,
        int256 deltaRealCollateral,
        int256 deltaShares
    ) public view returns (int256) {
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
        dividendWithOneMinusTargetLTV -= int256(int8(cases.cecbc)) * convertedAssets.futureCollateral.mulDivDown(int256(prices.collateralSlippage), 10**18);


        dividend += dividendWithOneMinusTargetLTV.mulDivUp(int256(Constants.LTV_DIVIDER - targetLTV), int256(Constants.LTV_DIVIDER));
        dividend += dividendWithTargetLTV.mulDivUp(int128(targetLTV), int256(Constants.LTV_DIVIDER));

        return dividend;
    }

    function calculateDividerByDeltaSharesAndDeltaRealCollateral(
        Cases memory cases,
        Prices memory prices, 
        ConvertedAssets memory convertedAssets
        //int256 deltaRealCollateral,
        //int256 deltaShares
    ) public view returns (int256) {
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
            dividerWithOneMinusTargetLTV -= int256(int8(cases.cecb)) * convertedAssets.userFutureRewardCollateral.mulDivUp(DIVIDER, convertedAssets.futureCollateral);
            dividerWithOneMinusTargetLTV += int256(int8(cases.cecbc)) * int256(prices.collateralSlippage);
            divider -= int256(int8(cases.cebc)) * convertedAssets.protocolFutureRewardBorrow.mulDivUp(DIVIDER, convertedAssets.futureCollateral);
            divider += int256(int8(cases.cecb)) * convertedAssets.protocolFutureRewardCollateral.mulDivDown((DIVIDER * int128(targetLTV)), (convertedAssets.futureCollateral * int256(Constants.LTV_DIVIDER)));
        }
        dividerWithOneMinusTargetLTV += int256(int8(cases.cmbc)) * int256(prices.collateralSlippage);
        
        divider += dividerWithOneMinusTargetLTV.mulDivDown(int256(Constants.LTV_DIVIDER - targetLTV), int256(Constants.LTV_DIVIDER));

        return divider;
    }

    function calculateDeltaFutureCollateralByDeltaSharesAndDeltaRealCollateral(
        Prices memory prices, 
        ConvertedAssets memory convertedAssets,
        Cases memory cases,
        int256 deltaRealCollateral,
        int256 deltaShares
    ) public view returns (int256, Cases memory) {

        int256 deltaFutureCollateral = 0;

        while (true) {

            int256 dividend = calculateDividentByDeltaSharesAndRealCollateral(cases, prices, convertedAssets, deltaRealCollateral, deltaShares);

            int256 divider = calculateDividerByDeltaSharesAndDeltaRealCollateral(cases, prices, convertedAssets);

            int256 DIVIDER = 10**18;

            if (divider == 0) {
                cases = CasesOperator.generateCase(cases.ncase + 1);
                continue;
            }
            // up because it's better for protocol
            deltaFutureCollateral = dividend.mulDivUp(DIVIDER, divider);

            bool validity = CasesOperator.checkCaseDeltaFutureCollateral(cases, convertedAssets, deltaFutureCollateral);

            if (validity) {
                break;
            }

            if (cases.ncase == 6) {
                // unexpected bihaviour
                return (0, cases);
            }
            cases = CasesOperator.generateCase(cases.ncase + 1);
        }

        return (deltaFutureCollateral, cases);
    }
}