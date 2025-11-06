// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintBorrowVaultState} from "../../structs/state/vault/max/MaxDepositMintBorrowVaultState.sol";
import {PreviewDepositVaultStateReader} from "PreviewDepositVaultStateReader.sol";

/**
 * @title MaxDepositMintBorrowVaultStateReader
 * @notice contract contains functionality to retrieve pure state needed for
 * max deposit mint borrow vault operations calculations
 */
contract MaxDepositMintBorrowVaultStateReader is PreviewDepositVaultStateReader {
    /**
     * @dev function to retrieve pure state needed for max deposit mint borrow vault operations
     */
    function maxDepositMintBorrowVaultState() internal view returns (MaxDepositMintBorrowVaultState memory) {
        return MaxDepositMintBorrowVaultState({
            previewDepositVaultState: previewDepositVaultState(),
            minProfitLtvDividend: minProfitLtvDividend,
            minProfitLtvDivider: minProfitLtvDivider,
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
        });
    }
}
