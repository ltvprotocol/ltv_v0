// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './PreviewDeposit.sol';

abstract contract MaxMint is PreviewDeposit {
    using uMulDiv for uint256;

    function maxMint(address) public view returns (uint256) {
        ConvertedAssets memory convertedAssets = recoverConvertedAssets(true);

        uint256 availableSpaceInShares = getAvailableSpaceInShares(convertedAssets, previewSupplyAfterFee(), true);

        // round up to assume smaller border
        uint256 minProfitRealBorrow = uint256(convertedAssets.realCollateral).mulDivUp(minProfitLTV, Constants.LTV_DIVIDER);
        if (uint256(convertedAssets.realBorrow) <= minProfitRealBorrow) {
            return 0;
        }

        uint256 maxDepositInUnderlying = uint256(convertedAssets.realBorrow) - minProfitRealBorrow;
        // round down to assume smaller border
        uint256 maxDepositInAssets = maxDepositInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle());
        uint256 maxMintShares = previewDeposit(maxDepositInAssets);

        return maxMintShares > availableSpaceInShares ? availableSpaceInShares : maxMintShares;
    }
}
