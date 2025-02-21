// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../Constants.sol';
import './TotalAssets.sol';
import '../math/MintRedeem.sol';

abstract contract PreviewMint is TotalAssets {
    using uMulDiv for uint256;

    function previewMint(uint256 shares) external view returns (uint256 assets) {
        uint256 sharesInAssets = shares.mulDivUp(totalAssets(), totalSupply());
        uint256 sharesInUnderlying = sharesInAssets.mulDivUp(getPrices().borrow, Constants.ORACLE_DIVIDER);
        
        Prices memory prices = getPrices();
        int256 assetsInUnderlying = MintRedeem.previewMintRedeem(int256(sharesInUnderlying), true, recoverConvertedAssets(), prices, targetLTV);

        if (assetsInUnderlying > 0) {
            return 0;
        }

        return uint256(-assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, prices.borrow);
    }
}
