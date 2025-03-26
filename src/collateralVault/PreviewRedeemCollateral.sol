// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../Constants.sol';
import '../math/MintRedeem.sol';
import '../MaxGrowthFee.sol';

abstract contract PreviewRedeemCollateral is MaxGrowthFee {
    using uMulDiv for uint256;

    function previewRedeemCollateral(uint256 shares) external view returns (uint256 assets) {
        Prices memory prices = getPrices();
        // round down to give less collateral
        uint256 sharesInUnderlying = shares.mulDivDown(totalAssetsCollateral(), previewSupplyAfterFee()).mulDivDown(prices.collateral, Constants.ORACLE_DIVIDER);
        int256 assetsInUnderlying = MintRedeem.previewMintRedeem(-1 * int256(sharesInUnderlying), false, recoverConvertedAssets(), prices, targetLTV);

        if (assetsInUnderlying > 0) {
            return 0;
        }

        // round down to give less collateral
        return uint256(-assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, prices.collateral);
    }
}
