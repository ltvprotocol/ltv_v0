// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./PreviewDepositVaultStateReader.sol";
import "src/structs/state/vault/MaxDepositMintBorrowVaultState.sol";

contract MaxDepositMintBorrowVaultStateReader is PreviewDepositVaultStateReader {
    function maxDepositMintBorrowVaultState() internal view returns (MaxDepositMintBorrowVaultState memory) {
        return MaxDepositMintBorrowVaultState({
            previewDepositVaultState: previewDepositVaultState(),
            minProfitLTVDividend: minProfitLTVDividend,
            minProfitLTVDivider: minProfitLTVDivider,
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
        });
    }
}
