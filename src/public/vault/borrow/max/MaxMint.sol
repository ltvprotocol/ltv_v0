// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../preview/PreviewDeposit.sol";
import "../preview/PreviewMint.sol";

abstract contract MaxMint is PreviewMint, PreviewDeposit {
    using uMulDiv for uint256;

    function maxMint(MaxDepositMintBorrowVaultState memory state) public pure returns (uint256) {
        return _maxMint(maxDepositMintBorrowVaultStateToMaxDepositMintBorrowVaultData(state));
    }

    function _maxMint(MaxDepositMintBorrowVaultData memory data) internal pure returns (uint256) {
        uint256 availableSpaceInShares = getAvailableSpaceInShares(
            data.previewBorrowVaultData.collateral,
            data.previewBorrowVaultData.borrow,
            data.maxTotalAssetsInUnderlying,
            data.previewBorrowVaultData.supplyAfterFee,
            data.previewBorrowVaultData.totalAssets,
            data.previewBorrowVaultData.borrowPrice
        );

        // round up to assume smaller border
        uint256 minProfitRealBorrow = uint256(data.realCollateral).mulDivUp(data.minProfitLTV, Constants.LTV_DIVIDER);
        if (uint256(data.realBorrow) <= minProfitRealBorrow) {
            return 0;
        }

        uint256 maxDepositInUnderlying = uint256(data.realBorrow) - minProfitRealBorrow;
        // round down to assume smaller border
        uint256 maxDepositInAssets =
            maxDepositInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, data.previewBorrowVaultData.borrowPrice);
        (uint256 maxMintShares,) = _previewDeposit(maxDepositInAssets, data.previewBorrowVaultData);

        return maxMintShares > availableSpaceInShares ? availableSpaceInShares : maxMintShares;
    }
}
