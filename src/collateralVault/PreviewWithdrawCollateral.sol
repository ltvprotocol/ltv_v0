// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../Constants.sol';
import '../borrowVault/TotalAssets.sol';
import '../math/DepositWithdraw.sol';
import '../MaxGrowthFee.sol';

abstract contract PreviewWithdrawCollateral is MaxGrowthFee {
    using uMulDiv for uint256;

    function previewWithdrawCollateral(uint256 assets) public view returns (uint256 shares) {
        Prices memory prices = getPrices();
        int256 sharesInUnderlying = DepositWithdraw.previewDepositWithdraw(-int256(assets), false, recoverConvertedAssets(false), prices, targetLTV);

        if (sharesInUnderlying > 0) {
            return 0;
        }

        // HODLer <=> withdrawer conflict, round in favor of HODLer, round up to burn more shares
        return uint256(-sharesInUnderlying).mulDivUp(Constants.ORACLE_DIVIDER, prices.borrow).mulDivUp(previewSupplyAfterFee(), _totalAssets(false));
    }
}
