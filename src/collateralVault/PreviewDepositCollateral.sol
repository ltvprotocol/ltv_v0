// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../Constants.sol';
import '../borrowVault/TotalAssets.sol';
import '../math/DepositWithdraw.sol';
import '../MaxGrowthFee.sol';

abstract contract PreviewDepositCollateral is MaxGrowthFee {
    using uMulDiv for uint256;

    function previewDepositCollateral(uint256 collateralAssets) public view returns (uint256 shares) {
        Prices memory prices = getPrices();
        int256 sharesInUnderlying = DepositWithdraw.previewDepositWithdraw(
            int256(collateralAssets),
            false,
            recoverConvertedAssets(),
            prices,
            targetLTV
        );

        if (sharesInUnderlying < 0) {
            return 0;
        }

        // round down to mint less shares
        return uint256(sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, prices.collateral).mulDivDown(previewSupplyAfterFee(), totalAssetsCollateral());
    }
}
