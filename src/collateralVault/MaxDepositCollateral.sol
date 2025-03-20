// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './PreviewMintCollateral.sol';

abstract contract MaxDepositCollateral is PreviewMintCollateral {
    using uMulDiv for uint256;

    function maxDepositCollateral(address) public view returns (uint256) {
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();


        uint256 availableSpaceInShares = getAvailableSpaceInShares(convertedAssets, previewSupplyAfterFee());
        uint256 availableSpaceInCollateral = previewMintCollateral(availableSpaceInShares);

        uint256 minProfitRealCollateral = uint256(convertedAssets.realBorrow).mulDivDown(Constants.LTV_DIVIDER, minProfitLTV);
        if (uint256(convertedAssets.realCollateral) >= minProfitRealCollateral) {
            return 0;
        }

        uint256 maxDepositInUnderlying = minProfitRealCollateral - uint256(convertedAssets.realCollateral);
        uint256 maxDepositInCollateral = maxDepositInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, getPriceCollateralOracle());

        return maxDepositInCollateral > availableSpaceInCollateral ? availableSpaceInCollateral : maxDepositInCollateral;
    }
}
