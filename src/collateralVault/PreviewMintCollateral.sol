// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../Constants.sol";
import "../borrowVault/TotalAssets.sol";
import "../math/MintRedeem.sol";
import '../math/DepositWithdraw.sol';

abstract contract PreviewMintCollateral is TotalAssets, DepositWithdraw, MintRedeem {

    using uMulDiv for uint256;

    function previewMintCollateral(uint256 shares) external view returns (uint256 collateralAssets) {

        uint256 sharesInAssets = shares.mulDivUp(totalAssets(), totalSupply());
        uint256 sharesInUnderlying = sharesInAssets.mulDivUp(getPriceBorrowOracle(), Constants.ORACLE_DIVIDER);

        int256 assetsInUnderlying = previewMintRedeem(int256(sharesInUnderlying), false);

        if (assetsInUnderlying < 0) {
            return 0;
        }

        return uint256(assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPriceCollateralOracle());
    }

}
