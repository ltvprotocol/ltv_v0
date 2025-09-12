// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/constants/Constants.sol";
import {MaxDepositMintBorrowVaultState} from "src/structs/state/vault/max/MaxDepositMintBorrowVaultState.sol";
import {MaxDepositMintBorrowVaultData} from "src/structs/data/vault/max/MaxDepositMintBorrowVaultData.sol";
import {PreviewMint} from "src/public/vault/read/borrow/preview/PreviewMint.sol";
import {PreviewDeposit} from "src/public/vault/read/borrow/preview/PreviewDeposit.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title MaxDeposit
 * @notice This contract contains max deposit function implementation.
 */
abstract contract MaxDeposit is PreviewMint, PreviewDeposit {
    using UMulDiv for uint256;

    /**
     * @dev see IBorrowVaultModule.maxDeposit
     */
    function maxDeposit(MaxDepositMintBorrowVaultState memory state) public pure returns (uint256) {
        return _maxDeposit(maxDepositMintStateToData(state));
    }

    /**
     * @dev base function to calculate max deposit
     */
    function _maxDeposit(MaxDepositMintBorrowVaultData memory data) internal pure returns (uint256) {
        uint256 availableSpaceInShares = getAvailableSpaceInShares(
            data.previewDepositBorrowVaultData.collateral,
            data.previewDepositBorrowVaultData.borrow,
            data.maxTotalAssetsInUnderlying,
            data.previewDepositBorrowVaultData.supplyAfterFee,
            data.previewDepositBorrowVaultData.depositTotalAssets,
            data.previewDepositBorrowVaultData.borrowPrice,
            data.previewDepositBorrowVaultData.borrowTokenDecimals
        );
        (uint256 availableSpaceInAssets,) = _previewMint(availableSpaceInShares, data.previewDepositBorrowVaultData);

        // round up to assume smaller border
        uint256 minProfitRealBorrow =
            uint256(data.realCollateral).mulDivUp(uint256(data.minProfitLtvDividend), uint256(data.minProfitLtvDivider));
        if (uint256(data.realBorrow) <= minProfitRealBorrow) {
            return 0;
        }

        // round down to assume smaller border
        uint256 maxDepositInAssets = (uint256(data.realBorrow) - minProfitRealBorrow).mulDivDown(
            Constants.ORACLE_DIVIDER, data.previewDepositBorrowVaultData.borrowPrice
        );

        return maxDepositInAssets > availableSpaceInAssets ? availableSpaceInAssets : maxDepositInAssets;
    }
}
