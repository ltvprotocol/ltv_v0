// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './PreviewMint.sol';

abstract contract MaxDeposit is PreviewMint {
    using uMulDiv for uint256;

    function maxDeposit(address) public view returns (uint256) {
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        uint256 totalAssetsInUnderlying = uint256(convertedAssets.collateral - convertedAssets.borrow);

        if (totalAssetsInUnderlying >= maxTotalAssetsInUnderlying) {
            return 0;
        }

        uint256 availableSpaceInShares = (maxTotalAssetsInUnderlying - totalAssetsInUnderlying)
            .mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle())
            .mulDivDown(previewSupplyAfterFee(), totalAssets());
        uint256 availableSpaceInAssets = previewMint(availableSpaceInShares);

        uint256 minProfitRealBorrow = uint256(convertedAssets.realCollateral).mulDivDown(minProfitLTV, Constants.LTV_DIVIDER);
        if (uint256(convertedAssets.realBorrow) <= minProfitRealBorrow) {
            return 0;
        }

        uint256 maxDepositInAssets = (uint256(convertedAssets.realBorrow) - minProfitRealBorrow).mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle());
        return maxDepositInAssets > availableSpaceInAssets ? availableSpaceInAssets : maxDepositInAssets;
    }
}
