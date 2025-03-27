// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './PreviewMint.sol';

abstract contract MaxDeposit is PreviewMint {
    using uMulDiv for uint256;

    function maxDeposit(address) public view returns (uint256) {
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        uint256 availableSpaceInShares = getAvailableSpaceInShares(convertedAssets, previewSupplyAfterFee());
        uint256 availableSpaceInAssets = previewMint(availableSpaceInShares);

        // round up to assume smaller border
        uint256 minProfitRealBorrow = uint256(convertedAssets.realCollateral).mulDivUp(minProfitLTV, Constants.LTV_DIVIDER);
        if (uint256(convertedAssets.realBorrow) <= minProfitRealBorrow) {
            return 0;
        }

        // round down to assume smaller border
        uint256 maxDepositInAssets = (uint256(convertedAssets.realBorrow) - minProfitRealBorrow).mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle());
        return maxDepositInAssets > availableSpaceInAssets ? availableSpaceInAssets : maxDepositInAssets;
    }
}
