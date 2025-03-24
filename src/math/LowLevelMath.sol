// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import '../Structs.sol';
import '../Constants.sol';
import '../utils/MulDiv.sol';

library LowLevelMath {
    using sMulDiv for int256;

    // delta real collateral needs to be rounded up to leave more collateral in protocol
    function calculateDeltaRealCollateralFromDeltaShares(
        int256 deltaShares,
        ConvertedAssets memory convertedAssets,
        uint128 targetLTV
    ) private pure returns (int256) {
        return
            (deltaShares +
                convertedAssets.futureCollateral +
                convertedAssets.userFutureRewardCollateral +
                // round up to leave more collateral in protocol
                convertedAssets.realCollateral.mulDivUp(int128(targetLTV), int256(Constants.LTV_DIVIDER)) -
                convertedAssets.realBorrow -
                convertedAssets.futureBorrow -
                convertedAssets.userFutureRewardBorrow).mulDivUp(int256(Constants.LTV_DIVIDER), int256(Constants.LTV_DIVIDER - targetLTV));
    }

    // delta real borrow needs to be rounded down to leave less borrow in the protocol
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

    // borrow case, delta real collateral needs to be rounded down to minimize shares minted
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
            deltaCollateral
            - deltaBorrow
            - convertedAssets.futureCollateral
            - convertedAssets.userFutureRewardCollateral
            + convertedAssets.futureBorrow
            + convertedAssets.userFutureRewardBorrow;
    }

    function calculateLowLevelShares(
        int256 deltaShares,
        ConvertedAssets memory convertedAssets,
        Prices memory prices,
        uint128 targetLTV,
        int256 totalAssets,
        int256 totalSupply
    ) external pure returns (int256, int256, int256) {
        // rounding down, less shares minted - bigger token price
        int256 deltaProtocolFutureRewardShares = (-convertedAssets.protocolFutureRewardCollateral + convertedAssets.protocolFutureRewardBorrow)
            .mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.borrow))
            .mulDivDown(totalSupply, totalAssets);

        // rounding up to assume more spending from user
        int256 deltaSharesInAssets = deltaShares.mulDivUp(totalAssets, totalSupply);
        int256 deltaSharesInUnderlying = deltaSharesInAssets.mulDivUp(int256(prices.borrow), int256(Constants.ORACLE_DIVIDER));

        int256 deltaRealCollateral = calculateDeltaRealCollateralFromDeltaShares(deltaSharesInUnderlying, convertedAssets, targetLTV);

        int256 deltaRealBorrow = calculateDeltaRealBorrowFromDeltaRealCollateral(deltaRealCollateral, convertedAssets, targetLTV);

        // round up to leave more collateral in protocol
        int256 deltaRealCollateralAssets = deltaRealCollateral.mulDivUp(int256(Constants.ORACLE_DIVIDER), int256(prices.collateral));
        // round down to leave less borrow in protocol
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
        // rounding down, less shares minted - bigger token price
        int256 deltaProtocolFutureRewardShares = (-convertedAssets.protocolFutureRewardCollateral + convertedAssets.protocolFutureRewardBorrow)
            .mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.borrow))
            .mulDivDown(totalSupply, totalAssets);


        int256 deltaRealCollateral;
        int256 deltaSharesInUnderlying;
        {
            // rounding up to give user less shares
            int256 deltaRealBorrow = deltaBorrowAssets.mulDivUp(int256(prices.borrow), int256(Constants.ORACLE_DIVIDER));
            deltaRealCollateral = calculateDeltaRealCollateralFromDeltaRealBorrow(deltaRealBorrow, convertedAssets, targetLTV);
            deltaSharesInUnderlying = calculateDeltaSharesFromDeltaRealCollateralAndDeltaRealBorrow(
                deltaRealCollateral,
                deltaRealBorrow,
                convertedAssets
            );
        }

        // rounding down, less shares minted - bigger token price
        int256 deltaShares = deltaSharesInUnderlying.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.borrow)).mulDivDown(
            totalSupply,
            totalAssets
        );
        // rounding up to keep more collateral in the protocol
        int256 deltaRealCollateralAssets = deltaRealCollateral.mulDivUp(int256(Constants.ORACLE_DIVIDER), int256(prices.collateral));

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
        // rounding down, less shares minted - bigger token price
        int256 deltaProtocolFutureRewardShares = (-convertedAssets.protocolFutureRewardCollateral + convertedAssets.protocolFutureRewardBorrow)
            .mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.borrow))
            .mulDivDown(totalSupply, totalAssets);

        int256 deltaRealBorrow;
        int256 deltaSharesInUnderlying;
        {
            // rounding down to mint less shares
            int256 deltaRealCollateral = deltaCollateralAssets.mulDivDown(int256(prices.collateral), int256(Constants.ORACLE_DIVIDER));

            deltaRealBorrow = calculateDeltaRealBorrowFromDeltaRealCollateral(deltaRealCollateral, convertedAssets, targetLTV);

            deltaSharesInUnderlying = calculateDeltaSharesFromDeltaRealCollateralAndDeltaRealBorrow(
                deltaRealCollateral,
                deltaRealBorrow,
                convertedAssets
            );
        }

        // rounding down, less shares minted - bigger token price
        int256 deltaShares = deltaSharesInUnderlying.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.borrow)).mulDivDown(
            totalSupply,
            totalAssets
        );
        // rounding down to keep less borrow in the protocol
        int256 deltaRealBorrowAssets = deltaRealBorrow.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(prices.borrow));

        return (deltaRealBorrowAssets, deltaShares, deltaProtocolFutureRewardShares);
    }
}
