// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import '../Structs.sol';
import '../Constants.sol';
import '../utils/MulDiv.sol';

library LowLevelMath {
    using sMulDiv for int256;

    function calculateDeltaRealCollateralFromDeltaShares(
        int256 deltaShares,
        ConvertedAssets memory convertedAssets,
        uint128 targetLTV
    ) private pure returns (int256) {
        return
            (deltaShares +
                convertedAssets.futureCollateral +
                convertedAssets.userFutureRewardCollateral +
                convertedAssets.realCollateral.mulDivDown(int128(targetLTV), int256(Constants.LTV_DIVIDER)) -
                convertedAssets.realBorrow -
                convertedAssets.futureBorrow -
                convertedAssets.userFutureRewardBorrow).mulDivDown(int256(Constants.LTV_DIVIDER), int256(Constants.LTV_DIVIDER - targetLTV));
    }

    function calculateDeltaRealBorrowFromDeltaRealCollateral(
        int256 deltaCollateral,
        ConvertedAssets memory convertedAssets,
        uint128 targetLTV
    ) private pure returns (int256) {
        return
            convertedAssets.realCollateral.mulDivDown(int128(targetLTV), int256(Constants.LTV_DIVIDER)) +
            deltaCollateral.mulDivDown(int128(targetLTV), int256(Constants.LTV_DIVIDER)) -
            convertedAssets.realBorrow;
    }

    function calculateDeltaRealCollateralFromDeltaRealBorrow(
        int256 deltaBorrow,
        ConvertedAssets memory convertedAssets,
        uint128 targetLTV
    ) private pure returns (int256) {
        return
            (convertedAssets.realBorrow + deltaBorrow).mulDivDown(int256(Constants.LTV_DIVIDER), int128(targetLTV)) - convertedAssets.realCollateral;
    }

    function calculateDeltaSharesFromDeltaRealCollateralAndDeltaRealBorrow(
        int256 deltaCollateral,
        int256 deltaBorrow,
        ConvertedAssets memory convertedAssets
    ) private pure returns (int256) {
        return
            deltaCollateral -
            deltaBorrow -
            convertedAssets.futureCollateral -
            convertedAssets.userFutureRewardCollateral +
            convertedAssets.futureBorrow +
            convertedAssets.userFutureRewardBorrow;
    }

    function calculateLowLevelShares(
        int256 deltaShares,
        ConvertedAssets memory convertedAssets,
        Prices memory prices,
        uint128 targetLTV,
        int256 totalAssets,
        int256 totalSupply
    ) external pure returns (int256, int256, int256) {
        int256 deltaProtocolFutureRewardShares = (-convertedAssets.protocolFutureRewardCollateral + convertedAssets.protocolFutureRewardBorrow)
            .mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.borrow))
            .mulDivDown(totalSupply, totalAssets);
        int256 deltaSharesInAssets = deltaShares.mulDivDown(totalAssets, totalSupply);
        int256 deltaSharesInUnderlying = deltaSharesInAssets.mulDivDown(int256(prices.borrow), int256(Constants.ORACLE_DIVIDER));

        int256 deltaRealCollateral = calculateDeltaRealCollateralFromDeltaShares(deltaSharesInUnderlying, convertedAssets, targetLTV);

        int256 deltaRealBorrow = calculateDeltaRealBorrowFromDeltaRealCollateral(deltaRealCollateral, convertedAssets, targetLTV);

        int256 deltaRealCollateralAssets = deltaRealCollateral.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.collateral));
        int256 deltaRealBorrowAssets = deltaRealBorrow.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.borrow));

        return (deltaRealCollateralAssets, deltaRealBorrowAssets, deltaProtocolFutureRewardShares);
    }

    function calculateLowLevelBorrow(
        int256 deltaBorrowAssets,
        ConvertedAssets memory convertedAssets,
        Prices memory prices,
        uint128 targetLTV,
        int256 totalAssets,
        int256 totalSupply
    ) external pure returns (int256, int256, int256) {
        int256 deltaProtocolFutureRewardShares = (-convertedAssets.protocolFutureRewardCollateral + convertedAssets.protocolFutureRewardBorrow)
            .mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.borrow))
            .mulDivDown(totalSupply, totalAssets);
        int256 deltaRealCollateral;
        int256 deltaSharesInUnderlying;
        {
            int256 deltaRealBorrow = deltaBorrowAssets.mulDivDown(int256(prices.borrow), int256(Constants.ORACLE_DIVIDER));
            deltaRealCollateral = calculateDeltaRealCollateralFromDeltaRealBorrow(deltaRealBorrow, convertedAssets, targetLTV);
            deltaSharesInUnderlying = calculateDeltaSharesFromDeltaRealCollateralAndDeltaRealBorrow(
                deltaRealCollateral,
                deltaRealBorrow,
                convertedAssets
            );
        }

        int256 deltaShares = deltaSharesInUnderlying.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.borrow)).mulDivDown(
            totalSupply,
            totalAssets
        );
        int256 deltaRealCollateralAssets = deltaRealCollateral.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.collateral));

        return (deltaRealCollateralAssets, deltaShares, deltaProtocolFutureRewardShares);
    }

    function calculateLowLevelCollateral(
        int256 deltaCollateralAssets,
        ConvertedAssets memory convertedAssets,
        Prices memory prices,
        uint128 targetLTV,
        int256 totalAssets,
        int256 totalSupply
    ) external pure returns (int256, int256, int256) {
        int256 deltaProtocolFutureRewardShares = (-convertedAssets.protocolFutureRewardCollateral + convertedAssets.protocolFutureRewardBorrow)
            .mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.borrow))
            .mulDivDown(totalSupply, totalAssets);

        int256 deltaRealBorrow;
        int256 deltaSharesInUnderlying;
        {
            int256 deltaRealCollateral = deltaCollateralAssets.mulDivDown(int256(prices.collateral), int256(Constants.ORACLE_DIVIDER));

            deltaRealBorrow = calculateDeltaRealBorrowFromDeltaRealCollateral(deltaRealCollateral, convertedAssets, targetLTV);

            deltaSharesInUnderlying = calculateDeltaSharesFromDeltaRealCollateralAndDeltaRealBorrow(
                deltaRealCollateral,
                deltaRealBorrow,
                convertedAssets
            );
        }

        int256 deltaShares = deltaSharesInUnderlying.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.borrow)).mulDivDown(
            totalSupply,
            totalAssets
        );
        int256 deltaRealBorrowAssets = deltaRealBorrow.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.borrow));

        return (deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);
    }
}
