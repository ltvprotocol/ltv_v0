// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../Constants.sol';
import '../borrowVault/TotalAssets.sol';
import '../math/DepositWithdraw.sol';
import '../math/MintRedeem.sol';

abstract contract PreviewDepositCollateral is TotalAssets, DepositWithdraw, MintRedeem {

    using uMulDiv for uint256;

    function previewDepositCollateral(uint256 collateralAssets) public view returns (uint256 shares) {
        int256 sharesInUnderlying = previewDepositWithdraw(int256(collateralAssets), false);

        uint256 sharesInAssets;
        if (sharesInUnderlying < 0) {
            return 0;
        } else {
            sharesInAssets = uint256(sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().collateral);
        }

        return sharesInAssets.mulDivDown(totalSupply(), totalAssets());
    }

}