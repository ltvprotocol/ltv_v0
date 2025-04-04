// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../Constants.sol';
import '../math/MintRedeem.sol';
import '../MaxGrowthFee.sol';

abstract contract PreviewMint is MaxGrowthFee {
    using uMulDiv for uint256;

    function previewMint(uint256 shares) public view returns (uint256 assets) {
        Prices memory prices = getPrices();
        // HODLer <=> depositor conflict, resolve in favor of HODLer, round up to receive more assets
        uint256 sharesInUnderlying = shares.mulDivUp(_totalAssets(true), previewSupplyAfterFee()).mulDivUp(prices.borrow, Constants.ORACLE_DIVIDER);

        int256 assetsInUnderlying = MintRedeem.previewMintRedeem(int256(sharesInUnderlying), true, recoverConvertedAssets(true), prices, targetLTV);

        if (assetsInUnderlying > 0) {
            return 0;
        }

        // HODLer <=> depositor conflict, resolve in favor of HODLer, round up to receive more assets
        return uint256(-assetsInUnderlying).mulDivUp(Constants.ORACLE_DIVIDER, prices.borrow);
    }
}
