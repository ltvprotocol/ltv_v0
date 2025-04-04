// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../Constants.sol';
import '../math/MintRedeem.sol';
import '../MaxGrowthFee.sol';

abstract contract PreviewMintCollateral is MaxGrowthFee {
    using uMulDiv for uint256;

    function previewMintCollateral(uint256 shares) public view returns (uint256 collateralAssets) {
        Prices memory prices = getPrices();
        // HODLer <=> depositor conflict, round in favor of HODLer, round up to receive more assets
        uint256 sharesInUnderlying = shares.mulDivUp(_totalAssets(true), previewSupplyAfterFee()).mulDivUp(prices.borrow, Constants.ORACLE_DIVIDER);
        int256 assetsInUnderlying = MintRedeem.previewMintRedeem(int256(sharesInUnderlying), false, recoverConvertedAssets(true), prices, targetLTV);

        if (assetsInUnderlying < 0) {
            return 0;
        }

        // HODLer <=> depositor conflict, round in favor of HODLer, round up to get more collateral
        return uint256(assetsInUnderlying).mulDivUp(Constants.ORACLE_DIVIDER, prices.collateral);
    }
}
