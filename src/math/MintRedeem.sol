// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "../Cases.sol";
import "../utils/MulDiv.sol";
import "./CommonBorrowCollateral.sol";
import "./deltaFutureCollateral/DeltaSharesAndDeltaRealCollateral.sol";
import './deltaFutureBorrow/DeltaSharesAndDeltaRealBorrow.sol';

abstract contract MintRedeem is CommonBorrowCollateral, DeltaSharesAndDeltaRealCollateral, DeltaSharesAndDeltaRealBorrow {

    using uMulDiv for uint256;

    function calculateMintRedeem(int256 shares, bool isBorrow) internal view returns (
        int256 assets,
        DeltaFuture memory deltaFuture
    ) {

        int256 deltaShares = shares;

        ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        Prices memory prices = getPrices();

        Cases memory cases = CasesOperator.generateCase(0);

        // ∆shares = ∆userCollateral − ∆userBorrow
        // ∆userBorrow = ∆userCollateral - ∆shares

        // ∆userCollateral = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral 
        // ∆userBorrow = ∆realBorrow + ∆futureBorrow + ∆userFutureRewardBorrow + ∆futurePaymentBorrow

        // ∆realBorrow = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral - ∆shares - ∆futureBorrow - ∆userFutureRewardBorrow - ∆futurePaymentBorrow
        if (isBorrow) {
            (deltaFuture.deltaFutureCollateral, cases) = calculateDeltaFutureCollateralByDeltaSharesAndDeltaRealCollateral(prices, convertedAssets, cases, 0, deltaShares);
            deltaFuture.deltaFutureBorrow = calculateDeltaFutureBorrowFromDeltaFutureCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);
        } else {
            (deltaFuture.deltaFutureBorrow, cases) = calculateDeltaFutureBorrowByDeltaSharesAndDeltaRealBorrow(prices, convertedAssets, cases, 0, deltaShares);
            deltaFuture.deltaFutureCollateral = calculateDeltaFutureCollateralFromDeltaFutureBorrow(cases, convertedAssets, deltaFuture.deltaFutureBorrow);
        }

        deltaFuture.deltaUserFutureRewardCollateral = calculateDeltaUserFutureRewardCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);
        
        deltaFuture.deltaProtocolFutureRewardCollateral = calculateDeltaProtocolFutureRewardCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);

        deltaFuture.deltaFuturePaymentCollateral = calculateDeltaFuturePaymentCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);

        deltaFuture.deltaUserFutureRewardBorrow = calculateDeltaUserFutureRewardBorrow(cases, convertedAssets, deltaFuture.deltaFutureBorrow);

        deltaFuture.deltaProtocolFutureRewardBorrow = calculateDeltaProtocolFutureRewardBorrow(cases, convertedAssets, deltaFuture.deltaFutureBorrow);

        deltaFuture.deltaFuturePaymentBorrow = calculateDeltaFuturePaymentBorrow(cases, convertedAssets, deltaFuture.deltaFutureBorrow);

        assets = deltaFuture.deltaFutureCollateral
               + deltaFuture.deltaUserFutureRewardCollateral
               + deltaFuture.deltaFuturePaymentCollateral
               - deltaShares
               - deltaFuture.deltaFutureBorrow
               - deltaFuture.deltaUserFutureRewardBorrow
               - deltaFuture.deltaFuturePaymentBorrow;

        assets = isBorrow ? assets : -assets;
    }

    function previewMintRedeem(int256 shares, bool isBorrow) internal view returns (
        int256 assets
    ) {
        (assets, ) = calculateMintRedeem(shares, isBorrow);
    }

}
