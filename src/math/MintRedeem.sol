// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../State.sol';
import '../Constants.sol';
import '../Structs.sol';
import '../Cases.sol';
import '../utils/MulDiv.sol';
import './CommonBorrowCollateral.sol';
import './deltaFutureCollateral/DeltaSharesAndDeltaRealCollateral.sol';
import './deltaFutureBorrow/DeltaSharesAndDeltaRealBorrow.sol';

library MintRedeem {
    using uMulDiv for uint256;

    function calculateMintRedeem(
        int256 shares,
        bool isBorrow,
        ConvertedAssets memory convertedAssets,
        Prices memory prices,
        uint128 targetLTV
    ) public pure returns (int256 assets, DeltaFuture memory deltaFuture) {
        int256 deltaShares = shares;

        Cases memory cases = CasesOperator.generateCase(0);

        // ∆shares = ∆userCollateral − ∆userBorrow
        // ∆userBorrow = ∆userCollateral - ∆shares

        // ∆userCollateral = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral
        // ∆userBorrow = ∆realBorrow + ∆futureBorrow + ∆userFutureRewardBorrow + ∆futurePaymentBorrow

        // ∆realBorrow = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral - ∆shares - ∆futureBorrow - ∆userFutureRewardBorrow - ∆futurePaymentBorrow
        if (isBorrow) {
            (deltaFuture.deltaFutureCollateral, cases) = DeltaSharesAndDeltaRealCollateral
                .calculateDeltaFutureCollateralByDeltaSharesAndDeltaRealCollateral(prices, convertedAssets, cases, 0, deltaShares, targetLTV);
            deltaFuture.deltaFutureBorrow = CommonBorrowCollateral.calculateDeltaFutureBorrowFromDeltaFutureCollateral(
                cases,
                convertedAssets,
                deltaFuture.deltaFutureCollateral
            );
        } else {
            (deltaFuture.deltaFutureBorrow, cases) = DeltaSharesAndDeltaRealBorrow.calculateDeltaFutureBorrowByDeltaSharesAndDeltaRealBorrow(
                prices,
                convertedAssets,
                cases,
                0,
                deltaShares,
                targetLTV
            );
            deltaFuture.deltaFutureCollateral = CommonBorrowCollateral.calculateDeltaFutureCollateralFromDeltaFutureBorrow(
                cases,
                convertedAssets,
                deltaFuture.deltaFutureBorrow
            );
        }

        deltaFuture.deltaUserFutureRewardCollateral = CommonBorrowCollateral.calculateDeltaUserFutureRewardCollateral(
            cases,
            convertedAssets,
            deltaFuture.deltaFutureCollateral
        );

        deltaFuture.deltaProtocolFutureRewardCollateral = CommonBorrowCollateral.calculateDeltaProtocolFutureRewardCollateral(
            cases,
            convertedAssets,
            deltaFuture.deltaFutureCollateral
        );

        deltaFuture.deltaFuturePaymentCollateral = CommonBorrowCollateral.calculateDeltaFuturePaymentCollateral(
            cases,
            convertedAssets,
            deltaFuture.deltaFutureCollateral,
            prices.collateralSlippage
        );

        deltaFuture.deltaUserFutureRewardBorrow = CommonBorrowCollateral.calculateDeltaUserFutureRewardBorrow(
            cases,
            convertedAssets,
            deltaFuture.deltaFutureBorrow
        );

        deltaFuture.deltaProtocolFutureRewardBorrow = CommonBorrowCollateral.calculateDeltaProtocolFutureRewardBorrow(
            cases,
            convertedAssets,
            deltaFuture.deltaFutureBorrow
        );

        deltaFuture.deltaFuturePaymentBorrow = CommonBorrowCollateral.calculateDeltaFuturePaymentBorrow(
            cases,
            convertedAssets,
            deltaFuture.deltaFutureBorrow,
            prices.borrowSlippage
        );

        assets =
            deltaFuture.deltaFutureCollateral +
            deltaFuture.deltaUserFutureRewardCollateral +
            deltaFuture.deltaFuturePaymentCollateral -
            deltaShares -
            deltaFuture.deltaFutureBorrow -
            deltaFuture.deltaUserFutureRewardBorrow -
            deltaFuture.deltaFuturePaymentBorrow;

        assets = isBorrow ? assets : -assets;
    }

    function previewMintRedeem(
        int256 shares,
        bool isBorrow,
        ConvertedAssets memory convertedAssets,
        Prices memory prices,
        uint128 targetLTV
    ) external pure returns (int256 assets) {
        (assets, ) = calculateMintRedeem(shares, isBorrow, convertedAssets, prices, targetLTV);
    }
}
