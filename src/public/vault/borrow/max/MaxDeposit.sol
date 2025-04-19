// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../preview/PreviewMint.sol';
import '../preview/PreviewDeposit.sol';
abstract contract MaxDeposit is PreviewMint, PreviewDeposit {
    using uMulDiv for uint256;

    function maxDeposit(DepositMintState memory state) public pure returns (uint256) {
        return _maxDeposit(depositMintStateToData(state));
    }

    function _maxDeposit(DepositMintData memory data) internal pure returns (uint256) {
        uint256 availableSpaceInShares = getAvailableSpaceInShares(
            data.vaultData.collateral,
            data.vaultData.borrow,
            data.vaultData.maxTotalAssetsInUnderlying,
            data.vaultData.supplyAfterFee,
            data.vaultData.totalAssets,
            data.vaultData.borrowPrice
        );
        (uint256 availableSpaceInAssets,) = _previewMint(availableSpaceInShares, data.vaultData);

        // round up to assume smaller border
        uint256 minProfitRealBorrow = uint256(data.vaultData.collateral).mulDivUp(data.minProfitLTV, Constants.LTV_DIVIDER);
        if (uint256(data.vaultData.borrow) <= minProfitRealBorrow) {
            return 0;
        }

        // round down to assume smaller border
        uint256 maxDepositInAssets = (uint256(data.vaultData.borrow) - minProfitRealBorrow).mulDivDown(
            Constants.ORACLE_DIVIDER,
            data.vaultData.borrowPrice
        );
        return maxDepositInAssets > availableSpaceInAssets ? availableSpaceInAssets : maxDepositInAssets;
    }
}
