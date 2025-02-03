// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../../Structs.sol";
import "../../Constants.sol";
import "../../Cases.sol";
import "../../utils/MulDiv.sol";
import "forge-std/console.sol";

contract DeltaSharesAndDeltaRealCollateral {

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
    ) public pure returns (int256) {
        // borrow
        // (1 - targetLTV) x deltaRealCollateral
        // (1 - targetLTV) x cecbc x -userFutureRewardCollateral
        // (1 - targetLTV) x ceccb x -futureCollateral x collateralSlippage
        // cecbc x - protocolFutureRewardBorrow
        // -shares
        // -targetLTV x collateral
        // -targetLTV x ceccb x protocolFutureRewardCollateral

        int256 DIVIDER = 10**18;

        int256 dividend = int256(convertedAssets.borrow);
        dividend -= int256(int8(cases.cecbc)) * convertedAssets.protocolFutureRewardBorrow;
        dividend -= deltaShares;

        int256 dividendWithTargetLTV = -int256(convertedAssets.collateral);
        dividendWithTargetLTV -= int256(int8(cases.ceccb)) * convertedAssets.protocolFutureRewardCollateral;

        int256 dividendWithOneMinusTargetLTV = deltaRealCollateral;
        dividendWithOneMinusTargetLTV -= int256(int8(cases.cecbc)) * int256(convertedAssets.userFutureRewardCollateral);
        dividendWithOneMinusTargetLTV -= int256(int8(cases.ceccb)) * convertedAssets.futureCollateral.mulDivDown(int256(prices.collateralSlippage), DIVIDER);


        dividend += dividendWithOneMinusTargetLTV.mulDivUp(int256(Constants.TARGET_LTV_DIVIDER - Constants.TARGET_LTV), int256(Constants.TARGET_LTV_DIVIDER));
        dividend += dividendWithTargetLTV.mulDivUp(int256(Constants.TARGET_LTV), int256(Constants.TARGET_LTV_DIVIDER));

        return dividend;
    }

    function calculateDividerByDeltaSharesAndDeltaRealCollateral(
        Cases memory cases,
        Prices memory prices, 
        ConvertedAssets memory convertedAssets
        //int256 deltaRealCollateral,
        //int256 deltaShares
    ) public pure returns (int256) {
        // (1 - targetLTV) x -1
        // (1 - targetLTV) x cebc x (userFutureRewardCollateral / futureCollateral) x -1
        // (1 - targetLTV) x cmcb x collateralSlippage
        // (1 - targetLTV) x ceccb x collateralSlippage
        // cebc x (protocolFutureRewardBorrow / futureCollateral) x -1
        // targetLTV x cecb x (protocolFutureRewardCollateral / futureCollateral)
        
        int256 DIVIDER = 10**18;

        int256 dividerWithOneMinusTargetLTV = -DIVIDER;
        int256 divider; 
        if (convertedAssets.futureCollateral != 0) {
            dividerWithOneMinusTargetLTV -= int256(int8(cases.cebc)) * convertedAssets.userFutureRewardCollateral.mulDivUp(DIVIDER, convertedAssets.futureCollateral);
            dividerWithOneMinusTargetLTV -= int256(int8(cases.ceccb)) * int256(prices.collateralSlippage) * DIVIDER;
            divider -= int256(int8(cases.cebc)) * convertedAssets.protocolFutureRewardBorrow.mulDivUp(DIVIDER, convertedAssets.futureCollateral);
            divider -= int256(int8(cases.cecb)) * convertedAssets.protocolFutureRewardCollateral.mulDivDown((DIVIDER * int256(Constants.TARGET_LTV)), (convertedAssets.futureCollateral * int256(Constants.TARGET_LTV_DIVIDER)));
        }
        dividerWithOneMinusTargetLTV -= int256(int8(cases.cmcb)) * int256(prices.collateralSlippage) * DIVIDER;
        
        divider += dividerWithOneMinusTargetLTV.mulDivDown(int256(Constants.TARGET_LTV_DIVIDER - Constants.TARGET_LTV), int256(Constants.TARGET_LTV_DIVIDER));

        return divider;
    }

    function calculateDeltaFutureCollateralByDeltaSharesAndDeltaRealCollateral(
        Prices memory prices, 
        ConvertedAssets memory convertedAssets,
        Cases memory cases,
        int256 deltaRealCollateral,
        int256 deltaShares
    ) public pure returns (int256) {

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
            console.log('dividend: ', dividend);
            console.log('divider : ', divider);
            deltaFutureCollateral = dividend.mulDivUp(DIVIDER, divider);

            bool validity = CasesOperator.checkCaseDeltaFutureCollateral(cases, convertedAssets, deltaFutureCollateral);

            if (validity) {
                console.log(cases.ncase);
                break;
            }

            if (cases.ncase == 6) {
                // unexpected bihaviour
                return 0;
            }

            cases = CasesOperator.generateCase(cases.ncase + 1);
        }

        return deltaFutureCollateral;
    }
}