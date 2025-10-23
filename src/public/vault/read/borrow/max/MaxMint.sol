// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintBorrowVaultState} from "src/structs/state/vault/max/MaxDepositMintBorrowVaultState.sol";
import {MaxDepositMintBorrowVaultData} from "src/structs/data/vault/max/MaxDepositMintBorrowVaultData.sol";
import {PreviewDeposit} from "src/public/vault/read/borrow/preview/PreviewDeposit.sol";
import {PreviewMint} from "src/public/vault/read/borrow/preview/PreviewMint.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title MaxMint
 * @notice This contract contains max mint function implementation.
 */
abstract contract MaxMint is PreviewMint, PreviewDeposit {
    using UMulDiv for uint256;

    /**
     * @dev see IBorrowVaultModule.maxMint
     */
    function maxMint(MaxDepositMintBorrowVaultState memory state) external view nonReentrantRead returns (uint256) {
        return _maxMint(maxDepositMintStateToData(state));
    }

    /**
     * @dev base function to calculate max mint
     */
    function _maxMint(MaxDepositMintBorrowVaultData memory data) internal pure returns (uint256) {
        uint256 availableSpaceInShares = getAvailableSpaceInShares(
            data.previewDepositBorrowVaultData.collateral,
            data.previewDepositBorrowVaultData.borrow,
            data.maxTotalAssetsInUnderlying,
            data.previewDepositBorrowVaultData.supplyAfterFee,
            data.previewDepositBorrowVaultData.depositTotalAssets,
            data.previewDepositBorrowVaultData.borrowPrice,
            data.previewDepositBorrowVaultData.borrowTokenDecimals
        );

        // round up to assume smaller border
        uint256 minProfitRealBorrow =
            uint256(data.realCollateral).mulDivUp(data.minProfitLtvDividend, data.minProfitLtvDivider);
        if (uint256(data.realBorrow) <= minProfitRealBorrow) {
            return 0;
        }

        uint256 maxDepositInUnderlying = uint256(data.realBorrow) - minProfitRealBorrow;
        // round down to assume smaller border
        uint256 maxDepositInAssets = maxDepositInUnderlying.mulDivDown(
            10 ** data.previewDepositBorrowVaultData.borrowTokenDecimals, data.previewDepositBorrowVaultData.borrowPrice
        );
        (uint256 maxMintShares,) = _previewDeposit(maxDepositInAssets, data.previewDepositBorrowVaultData);

        return maxMintShares > availableSpaceInShares ? availableSpaceInShares : maxMintShares;
    }
}
