// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {MaxDepositMintBorrowVaultState} from "src/structs/state/vault/MaxDepositMintBorrowVaultState.sol";
import {MaxDepositMintBorrowVaultData} from "src/structs/data/vault/MaxDepositMintBorrowVaultData.sol";
import {PreviewDeposit} from "src/public/vault/read/borrow/preview/PreviewDeposit.sol";
import {PreviewMint} from "src/public/vault/read/borrow/preview/PreviewMint.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract MaxMint is PreviewMint, PreviewDeposit {
    using uMulDiv for uint256;

    function maxMint(MaxDepositMintBorrowVaultState memory state) public pure returns (uint256) {
        return _maxMint(maxDepositMintStateToData(state));
    }

    function _maxMint(MaxDepositMintBorrowVaultData memory data) internal pure returns (uint256) {
        uint256 availableSpaceInShares = getAvailableSpaceInShares(
            data.previewDepositBorrowVaultData.collateral,
            data.previewDepositBorrowVaultData.borrow,
            data.maxTotalAssetsInUnderlying,
            data.previewDepositBorrowVaultData.supplyAfterFee,
            data.previewDepositBorrowVaultData.depositTotalAssets,
            data.previewDepositBorrowVaultData.borrowPrice
        );

        // round up to assume smaller border
        uint256 minProfitRealBorrow =
            uint256(data.realCollateral).mulDivUp(data.minProfitLtvDividend, data.minProfitLtvDivider);
        if (uint256(data.realBorrow) <= minProfitRealBorrow) {
            return 0;
        }

        uint256 maxDepositInUnderlying = uint256(data.realBorrow) - minProfitRealBorrow;
        // round down to assume smaller border
        uint256 maxDepositInAssets =
            maxDepositInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, data.previewDepositBorrowVaultData.borrowPrice);
        (uint256 maxMintShares,) = _previewDeposit(maxDepositInAssets, data.previewDepositBorrowVaultData);

        return maxMintShares > availableSpaceInShares ? availableSpaceInShares : maxMintShares;
    }
}
