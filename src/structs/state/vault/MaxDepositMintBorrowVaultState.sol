// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewDepositVaultState} from "src/structs/state/vault/PreviewDepositVaultState.sol";

struct MaxDepositMintBorrowVaultState {
    PreviewDepositVaultState previewDepositVaultState;
    uint256 maxTotalAssetsInUnderlying;
    uint16 minProfitLtvDividend;
    uint16 minProfitLtvDivider;
}
