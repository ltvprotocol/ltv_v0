// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../Constants.sol";
import '../MaxGrowthFee.sol';
import "../math/MintRedeem.sol";

abstract contract PreviewRedeem is MaxGrowthFee {
    using uMulDiv for uint256;

    function previewRedeem(uint256 shares) external view returns (uint256 assets) {
        // round down to give less assets for provided shares
        Prices memory prices = getPrices();
        uint256 sharesInUnderlying = shares.mulDivDown(_totalAssets(false), previewSupplyAfterFee()).mulDivDown(prices.borrow, Constants.ORACLE_DIVIDER);
        int256 assetsInUnderlying = MintRedeem.previewMintRedeem(
            -1 * int256(sharesInUnderlying),
            true,
            recoverConvertedAssets(false),
            prices,
            targetLTV
        );

        if (assetsInUnderlying < 0) {
            return 0;
        }

        // give less assets
        return uint256(assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, prices.borrow);
    }
}
