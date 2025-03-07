// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './PreviewDepositCollateral.sol';

abstract contract MaxMintCollateral is PreviewDepositCollateral {
  using uMulDiv for uint256;

  function maxMintCollateral(address) public view returns(uint256) {
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        uint256 totalAssetsInUnderlying = uint256(convertedAssets.collateral - convertedAssets.borrow);

        if (totalAssetsInUnderlying >= maxTotalAssetsInUnderlying) {
            return 0;
        }

        uint256 availableSpaceInShares = (maxTotalAssetsInUnderlying - totalAssetsInUnderlying)
            .mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle())
            .mulDivDown(previewSupplyAfterFee(), totalAssets());

        uint256 minProfitRealCollateral = uint256(convertedAssets.realBorrow).mulDivDown(Constants.LTV_DIVIDER, minProfitLTV);
        if (uint256(convertedAssets.realCollateral) >= minProfitRealCollateral) {
            return 0;
        }

        uint256 maxDepositInUnderlying = minProfitRealCollateral - uint256(convertedAssets.realCollateral);
        uint256 maxDepositInCollateral = maxDepositInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, getPriceCollateralOracle());
        uint256 maxDepositInShares = previewDepositCollateral(maxDepositInCollateral);

        return maxDepositInShares > availableSpaceInShares ? availableSpaceInShares : maxDepositInShares;
  }
}