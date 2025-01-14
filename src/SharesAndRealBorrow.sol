// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./Structs.sol";
import "./Constants.sol";
import "./Cases.sol";

contract SharesAndRealBorrow {

    function calculateDividentSharesAndRealBorrow(
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

        int256 DEVIDER = 10**18;

        int256 divindent = -int256(convertedAssets.borrow);
        divindent -= int256(int8(cases.cecbc)) * convertedAssets.protocolFutureRewardBorrow;

        int256 divindentWithOneMinusTargetLTV = deltaRealBorrow;
        divindentWithOneMinusTargetLTV -= int256(int8(cases.cecbc)) * int256(convertedAssets.userFutureRewardBorrow);
        divindentWithOneMinusTargetLTV -= int256(int8(cases.ceccb)) * int256(convertedAssets.futureBorrow) * int256(prices.borrowSlippage) / DEVIDER;

        int256 divindentWithTargetLTV = -int256(convertedAssets.collateral);
        divindentWithTargetLTV -= int256(int8(cases.ceccb)) * deltaShares;
        divindentWithTargetLTV -= int256(int8(cases.ceccb)) * convertedAssets.protocolFutureRewardCollateral;

        divindent += (divindentWithOneMinusTargetLTV * int256(Constants.TARGET_LTV_DEVIDER - Constants.TARGET_LTV)) / int256(Constants.TARGET_LTV_DEVIDER);
        divindent += (divindentWithTargetLTV * int256(Constants.TARGET_LTV)) / int256(Constants.TARGET_LTV_DEVIDER);

        return divindent;
    }

    function calculateDeviderSharesAndRealBorrow(
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
        
        int256 DEVIDER = 10**18;

        int256 deviderWithOneMinusTargetLTV = -DEVIDER;
        deviderWithOneMinusTargetLTV = -int256(int8(cases.cebc)) * convertedAssets.userFutureRewardBorrow * DEVIDER / convertedAssets.futureBorrow;
        deviderWithOneMinusTargetLTV = -int256(int8(cases.cmcb)) * int256(prices.borrowSlippage) * DEVIDER;
        deviderWithOneMinusTargetLTV = -int256(int8(cases.ceccb)) * int256(prices.borrowSlippage) * DEVIDER;

        int256 devider = deviderWithOneMinusTargetLTV * int256(Constants.TARGET_LTV_DEVIDER - Constants.TARGET_LTV) / int256(Constants.TARGET_LTV_DEVIDER);

        devider += -int256(int8(cases.cebc)) * convertedAssets.protocolFutureRewardBorrow * DEVIDER / convertedAssets.futureBorrow;
        devider = int256(int8(cases.cecb)) * convertedAssets.protocolFutureRewardCollateral * DEVIDER * int256(Constants.TARGET_LTV) / (convertedAssets.futureBorrow * int256(Constants.TARGET_LTV_DEVIDER));

        return devider;
    }

    function calculateDeltaFutureBorrowSharesAndRealBorrow(
        Prices memory prices, 
        ConvertedAssets memory convertedAssets,
        int256 deltaRealBorrow,
        int256 deltaShares
    ) public view returns (int256) {

        // ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        // Prices memory prices = getPrices();
        Cases memory cases = CasesOperator.generateCase(0);

        int256 deltaFutureBorrow = 0;

        while (true) {

            int256 divindent = calculateDividentSharesAndRealBorrow(cases, prices, convertedAssets, deltaRealBorrow, deltaShares);

            int256 divider = calculateDeviderSharesAndRealBorrow(cases, prices, convertedAssets);

            int256 DEVIDER = 10**18;

            deltaFutureBorrow = divindent * DEVIDER / divider;

            bool validity = CasesOperator.checkCaseDeltaFutureBorrow(cases, convertedAssets, deltaFutureBorrow);

            if (validity) {
                break;
            }

            if (cases.ncase == 6) {
                // unexpected bihaviour
                return 0;
            }

            cases = CasesOperator.generateCase(cases.ncase + 1);
        }

        return deltaFutureBorrow;
    }
}