// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./Structs.sol";
import "./Constants.sol";
import "./Cases.sol";

contract SharesAndRealCollateral {

    function calculateDividentSharesAndRealCollateral(
        Cases memory cases,
        Prices memory prices, 
        ConvertedAssets memory convertedAssets,
        int256 deltaRealCollateral,
        int256 deltaShares
    ) public view returns (int256) {
        // borrow
        // (1 - targetLTV) x deltaRealCollateral
        // (1 - targetLTV) x cecbc x -userFutureRewardCollateral
        // (1 - targetLTV) x ceccb x -futureCollateral x collateralSlippage
        // cecbc x - protocolFutureRewardBorrow
        // -shares
        // -targetLTV x collateral
        // -targetLTV x ceccb x - protocolFutureRewardCollateral

        int256 DEVIDER = 10**18;

        int256 divindent = -int256(convertedAssets.borrow);
        divindent -= int256(int8(cases.cecbc)) * convertedAssets.protocolFutureRewardBorrow;
        divindent -= int256(int8(cases.ceccb)) * deltaShares;

        int256 divindentWithOneMinusTargetLTV = deltaRealCollateral;
        divindentWithOneMinusTargetLTV -= int256(int8(cases.cecbc)) * int256(convertedAssets.userFutureRewardCollateral);
        divindentWithOneMinusTargetLTV -= int256(int8(cases.ceccb)) * int256(convertedAssets.futureCollateral) * int256(prices.collateralSlippage) / DEVIDER;

        int256 divindentWithTargetLTV = -int256(convertedAssets.collateral);
        divindentWithTargetLTV -= int256(int8(cases.ceccb)) * convertedAssets.protocolFutureRewardCollateral;

        divindent += (divindentWithOneMinusTargetLTV * int256(Constants.TARGET_LTV_DEVIDER - Constants.TARGET_LTV)) / int256(Constants.TARGET_LTV_DEVIDER);
        divindent += (divindentWithTargetLTV * int256(Constants.TARGET_LTV)) / int256(Constants.TARGET_LTV_DEVIDER);

        return divindent;
    }

    function calculateDeviderSharesAndRealCollateral(
        Cases memory cases,
        Prices memory prices, 
        ConvertedAssets memory convertedAssets
        //int256 deltaRealCollateral,
        //int256 deltaShares
    ) public view returns (int256) {
        // (1 - targetLTV) x -1
        // (1 - targetLTV) x cebc x (userFutureRewardCollateral / futureCollateral)
        // (1 - targetLTV) x cmcb x collateralSlippage
        // (1 - targetLTV) x ceccb x collateralSlippage
        // cebc x (protocolFutureRewardBorrow / futureCollateral)
        // -targetLTV x cecb x (protocolFutureRewardCollateral / futureCollateral)
        
        int256 DEVIDER = 10**18;

        int256 deviderWithOneMinusTargetLTV = -DEVIDER;
        deviderWithOneMinusTargetLTV = -int256(int8(cases.cebc)) * convertedAssets.userFutureRewardBorrow * DEVIDER / convertedAssets.futureBorrow;
        deviderWithOneMinusTargetLTV = -int256(int8(cases.cmcb)) * int256(prices.borrowSlippage) * DEVIDER;
        deviderWithOneMinusTargetLTV = -int256(int8(cases.ceccb)) * int256(prices.borrowSlippage) * DEVIDER;

        int256 devider = deviderWithOneMinusTargetLTV * int256(Constants.TARGET_LTV_DEVIDER - Constants.TARGET_LTV) / int256(Constants.TARGET_LTV_DEVIDER);

        devider += -int256(int8(cases.cebc)) * convertedAssets.protocolFutureRewardBorrow * DEVIDER / convertedAssets.futureCollateral;
        devider = int256(int8(cases.cecb)) * convertedAssets.protocolFutureRewardCollateral * DEVIDER * int256(Constants.TARGET_LTV) / (convertedAssets.futureCollateral * int256(Constants.TARGET_LTV_DEVIDER));

        return devider;
    }

    function calculateDeltaFutureCollateralSharesAndRealCollateral(
        Prices memory prices, 
        ConvertedAssets memory convertedAssets,
        int256 deltaRealCollateral,
        int256 deltaShares
    ) public view returns (int256) {

        // ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        // Prices memory prices = getPrices();
        Cases memory cases = CasesOperator.generateCase(0);

        int256 deltaFutureCollateral = 0;

        while (true) {

            int256 divindent = calculateDividentSharesAndRealCollateral(cases, prices, convertedAssets, deltaRealCollateral, deltaShares);

            int256 divider = calculateDeviderSharesAndRealCollateral(cases, prices, convertedAssets);

            int256 DEVIDER = 10**18;

            deltaFutureCollateral = divindent * DEVIDER / divider;

            bool validity = CasesOperator.checkCaseDeltaFutureCollateral(cases, convertedAssets, deltaFutureCollateral);

            if (validity) {
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