// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../preview/PreviewMint.sol';
import '../preview/PreviewDeposit.sol';

abstract contract MaxDeposit is PreviewMint, PreviewDeposit {
    using uMulDiv for uint256;

    function maxDeposit(MaxDepositMintBorrowVaultState memory state) public pure returns (uint256) {
        return _maxDeposit(maxDepositMintBorrowVaultStateToMaxDepositMintBorrowVaultData(state));
    }

    function _maxDeposit(MaxDepositMintBorrowVaultData memory data) internal pure returns (uint256) {
        uint256 availableSpaceInShares = getAvailableSpaceInShares(
            data.previewBorrowVaultData.collateral,
            data.previewBorrowVaultData.borrow,
            data.maxTotalAssetsInUnderlying,
            data.previewBorrowVaultData.supplyAfterFee,
            data.previewBorrowVaultData.totalAssets,
            data.previewBorrowVaultData.borrowPrice
        );
        (uint256 availableSpaceInAssets, ) = _previewMint(availableSpaceInShares, data.previewBorrowVaultData);

        // round up to assume smaller border
        uint256 minProfitRealBorrow = uint256(data.realCollateral).mulDivUp(data.minProfitLTV, Constants.LTV_DIVIDER);
        if (uint256(data.realBorrow) <= minProfitRealBorrow) {
            return 0;
        }

        // round down to assume smaller border
        uint256 maxDepositInAssets = (uint256(data.realBorrow) - minProfitRealBorrow).mulDivDown(
            Constants.ORACLE_DIVIDER,
            data.previewBorrowVaultData.borrowPrice
        );
        
        return maxDepositInAssets > availableSpaceInAssets ? availableSpaceInAssets : maxDepositInAssets;
    }
}
