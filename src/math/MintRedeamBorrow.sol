// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "../Cases.sol";
import "../SharesAndRealCollateral.sol";
import "../utils/MulDiv.sol";
import "./CommonBorrowCollateral.sol";

abstract contract MintRedeamBorrow is State, SharesAndRealCollateral, CommonBorrowCollateral {

    using uMulDiv for uint256;

    function previewMintRedeamBorrow(int256 shares) internal view returns (int256 assets) {

        int256 deltaShares = shares;
        int256 deltaRealCollateral = 0;

        ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        Prices memory prices = getPrices();

        Cases memory cases = CasesOperator.generateCase(0);

        int256 deltaFutureCollateral = calculateDeltaFutureCollateralSharesAndRealCollateral(prices, convertedAssets, deltaRealCollateral, deltaShares);

        // ∆shares = ∆userCollateral − ∆userBorrow
        // ∆userBorrow = ∆userCollateral - ∆shares
        // ∆userCollateral = ∆realCollateral + ∆futureCollateral + ∆userFutureRewardCollateral + ∆futurePaymentCollateral
        // 

        int256 deltaFutureBorrow = calculateDeltaFutureBorrowFromDeltaFutureCollateral(cases, convertedAssets, deltaFutureCollateral);

        int256 signedShares = deltaRealCollateral 
                        + deltaFutureCollateral
                        + calculateDeltaUserFutureRewardCollateral(cases, convertedAssets, deltaFutureCollateral)
                        + calculateDeltaFuturePaymentCollateral(cases, convertedAssets, deltaFutureCollateral)
                        - deltaShares;

        return signedShares;
    }

}
