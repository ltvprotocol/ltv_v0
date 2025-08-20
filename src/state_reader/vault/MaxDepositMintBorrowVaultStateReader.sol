// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintBorrowVaultState} from "src/structs/state/vault/MaxDepositMintBorrowVaultState.sol";
import {PreviewDepositVaultStateReader} from "src/state_reader/vault/PreviewDepositVaultStateReader.sol";

contract MaxDepositMintBorrowVaultStateReader is PreviewDepositVaultStateReader {
    function maxDepositMintBorrowVaultState() internal view returns (MaxDepositMintBorrowVaultState memory) {
        return MaxDepositMintBorrowVaultState({
            previewDepositVaultState: previewDepositVaultState(),
            minProfitLtvDividend: minProfitLtvDividend,
            minProfitLtvDivider: minProfitLtvDivider,
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
        });
    }
}
