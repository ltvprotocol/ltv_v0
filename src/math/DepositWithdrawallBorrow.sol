// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "../Cases.sol";
import "../RealBorrowAndRealCollateral.sol";
import "../utils/MulDiv.sol";
import "./CommonBorrowCollateral.sol";

abstract contract DepositWithdrawallBorrow is State, RealBorrowAndRealCollateral, CommonBorrowCollateral {

    using MulDiv for uint256;

    function previewDepositWithdrawallBorrow(int256 assets) internal view returns (int256 shares) {

        int256 deltaRealBorrow = assets * int256(getPriceBorrowOracle() / Constants.ORACLE_DEVIDER);
        int256 deltaRealCollateral = 0;

        ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        Prices memory prices = getPrices();

        Cases memory cases = CasesOperator.generateCase(0);

        int256 deltaFutureCollateral = calculateDeltaFutureCollateralRealBorrowAndRealCollateral(prices, convertedAssets, deltaRealCollateral, deltaRealBorrow);

        // ∆shares = ∆userCollateral − ∆userBorrow
        // ∆userCollateral = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral
        // ∆userBorrow = ∆realBorrow + ∆futureBorrow + ∆userFutureRewardBorrow + ∆futurePaymentBorrow

        int256 deltaFutureBorrow = calculateDeltaFutureBorrowFromDeltaFutureCollateral(cases, convertedAssets, deltaFutureCollateral);

        int256 signedShares = deltaRealCollateral 
                        + deltaFutureCollateral
                        + calculateDeltaUserFutureRewardCollateral(cases, convertedAssets, deltaFutureCollateral)
                        + calculateDeltaFuturePaymentCollateral(cases, convertedAssets, deltaFutureCollateral)
                        - deltaRealBorrow
                        - deltaFutureBorrow
                        - calculateDeltaUserFutureRewardBorrow(cases, convertedAssets, deltaFutureBorrow)
                        - calculateDeltaFuturePaymentBorrow(cases, convertedAssets, deltaFutureBorrow);

        return signedShares;
    }

}
