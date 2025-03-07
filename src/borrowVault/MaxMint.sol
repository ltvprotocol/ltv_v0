// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './PreviewDeposit.sol';

abstract contract MaxMint is PreviewDeposit {
    using uMulDiv for uint256;

    function maxMint(address) public view returns (uint256) {
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        uint256 totalAssetsInUnderlying = uint256(convertedAssets.collateral - convertedAssets.borrow);

        if (totalAssetsInUnderlying >= maxTotalAssetsInUnderlying) {
            return 0;
        }

        uint256 availableSpaceInUnderlying = maxTotalAssetsInUnderlying - totalAssetsInUnderlying;
        uint256 availableSpaceInShares = availableSpaceInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle()).mulDivDown(
            previewSupplyAfterFee(),
            totalAssets()
        );

        uint256 minProfitRealBorrow = uint256(convertedAssets.realCollateral).mulDivDown(minProfitLTV, Constants.LTV_DIVIDER);
        if (uint256(convertedAssets.realBorrow) <= minProfitRealBorrow) {
            return 0;
        }

        uint256 maxDepositInUnderlying = uint256(convertedAssets.realBorrow) - minProfitRealBorrow;
        uint256 maxDepositInAssets = maxDepositInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle());
        uint256 maxMintShares = previewDeposit(maxDepositInAssets);
        maxDepositInUnderlying = maxDepositInUnderlying > availableSpaceInUnderlying ? availableSpaceInUnderlying : maxDepositInUnderlying;

        return maxMintShares > availableSpaceInShares ? availableSpaceInShares : maxMintShares;
    }
}
