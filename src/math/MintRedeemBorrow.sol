// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "../Cases.sol";
import "../SharesAndRealCollateral.sol";
import "../utils/MulDiv.sol";
import "./CommonBorrowCollateral.sol";
import "./deltaFutureCollateral/DeltaSharesAndDeltaRealCollateral.sol";

abstract contract MintRedeemBorrow is CommonBorrowCollateral, SharesAndRealCollateral, DeltaSharesAndDeltaRealCollateral {

    using uMulDiv for uint256;

    function calculateMintRedeemBorrow(int256 shares) internal view returns (
        int256 assets,
        DeltaFuture memory deltaFuture
    ) {

        int256 deltaShares = shares;
        int256 deltaRealCollateral = 0;

        ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        Prices memory prices = getPrices();

        Cases memory cases = CasesOperator.generateCase(0);

        (deltaFuture.deltaFutureCollateral, cases) = calculateDeltaFutureCollateralByDeltaSharesAndDeltaRealCollateral(prices, convertedAssets, cases, deltaRealCollateral, deltaShares);
                                       
        // ∆shares = ∆userCollateral − ∆userBorrow
        // ∆userBorrow = ∆userCollateral - ∆shares

        // ∆userCollateral = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral 
        // ∆userBorrow = ∆realBorrow + ∆futureBorrow + ∆userFutureRewardBorrow + ∆futurePaymentBorrow

        // ∆realBorrow = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral - ∆shares - ∆futureBorrow - ∆userFutureRewardBorrow - ∆futurePaymentBorrow

        deltaFuture.deltaFutureBorrow = calculateDeltaFutureBorrowFromDeltaFutureCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);

        deltaFuture.deltaUserFutureRewardCollateral = calculateDeltaUserFutureRewardCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);

        deltaFuture.deltaFuturePaymentCollateral = calculateDeltaFuturePaymentCollateral(cases, convertedAssets, deltaFuture.deltaFutureCollateral);

        deltaFuture.deltaUserFutureRewardBorrow = calculateDeltaUserFutureRewardBorrow(cases, convertedAssets, deltaFuture.deltaFutureBorrow);

        deltaFuture.deltaFuturePaymentBorrow = calculateDeltaFuturePaymentBorrow(cases, convertedAssets, deltaFuture.deltaFutureBorrow);

        assets = deltaRealCollateral 
                        + deltaFuture.deltaFutureCollateral
                        + deltaFuture.deltaUserFutureRewardCollateral
                        + deltaFuture.deltaFuturePaymentCollateral
                        - deltaShares
                        - deltaFuture.deltaFutureBorrow
                        - deltaFuture.deltaUserFutureRewardBorrow
                        - deltaFuture.deltaFuturePaymentBorrow;
    }

    function previewMintRedeemBorrow(int256 shares) internal view returns (
        int256 assets
    ) {
        (assets, ) = calculateMintRedeemBorrow(shares);
    }

}
