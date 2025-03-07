// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../Constants.sol";
import "../math/MintRedeem.sol";
import '../MaxGrowthFee.sol';

abstract contract PreviewMint is MaxGrowthFee {
    using uMulDiv for uint256;

    function previewMint(uint256 shares) public view returns (uint256 assets) {
        uint256 sharesInAssets = shares.mulDivUp(totalAssets(), previewSupplyAfterFee());
        uint256 sharesInUnderlying = sharesInAssets.mulDivUp(getPrices().borrow, Constants.ORACLE_DIVIDER);
        
        Prices memory prices = getPrices();
        int256 assetsInUnderlying = MintRedeem.previewMintRedeem(int256(sharesInUnderlying), true, recoverConvertedAssets(), prices, targetLTV);

        if (assetsInUnderlying > 0) {
            return 0;
        }

        return uint256(-assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, prices.borrow);
    }
}
