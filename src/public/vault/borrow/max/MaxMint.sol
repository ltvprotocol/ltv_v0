// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../preview/PreviewDeposit.sol';
import '../preview/PreviewMint.sol';

abstract contract MaxMint is PreviewMint,PreviewDeposit {
    using uMulDiv for uint256;

    function maxMint(DepositMintState memory state) public pure returns (uint256) {
        return _maxMint(depositMintStateToData(state));
    }

    function _maxMint(DepositMintData memory data) internal pure returns (uint256) {
        uint256 availableSpaceInShares = getAvailableSpaceInShares(
            data.vaultData.collateral,
            data.vaultData.borrow,
            data.vaultData.maxTotalAssetsInUnderlying,
            data.vaultData.supplyAfterFee,
            data.vaultData.totalAssets,
            data.vaultData.borrowPrice
        );

        // round up to assume smaller border
        uint256 minProfitRealBorrow = uint256(data.vaultData.collateral).mulDivUp(data.minProfitLTV, Constants.LTV_DIVIDER);
        if (uint256(data.vaultData.borrow) <= minProfitRealBorrow) {
            return 0;
        }

        uint256 maxDepositInUnderlying = uint256(data.vaultData.borrow) - minProfitRealBorrow;
        // round down to assume smaller border
        uint256 maxDepositInAssets = maxDepositInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, data.vaultData.borrowPrice);
        (uint256 maxMintShares,) = _previewDeposit(maxDepositInAssets, data.vaultData);

        return maxMintShares > availableSpaceInShares ? availableSpaceInShares : maxMintShares;
    }
}
