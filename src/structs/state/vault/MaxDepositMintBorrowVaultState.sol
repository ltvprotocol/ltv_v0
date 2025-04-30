// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./PreviewVaultState.sol";

struct MaxDepositMintBorrowVaultState {
    PreviewVaultState previewVaultState;
    uint256 maxTotalAssetsInUnderlying;
    uint256 minProfitLTV;
} 