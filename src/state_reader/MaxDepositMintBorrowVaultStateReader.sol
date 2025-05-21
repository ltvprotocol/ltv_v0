// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './PreviewVaultStateReader.sol';
import 'src/structs/state/vault/MaxDepositMintBorrowVaultState.sol';

contract MaxDepositMintBorrowVaultStateReader is PreviewVaultStateReader {
    function maxDepositMintBorrowVaultState() internal view returns (MaxDepositMintBorrowVaultState memory) {
        return
            MaxDepositMintBorrowVaultState({
                previewVaultState: previewVaultState(),
                minProfitLTV: minProfitLTV,
                maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
            });
    }
}
