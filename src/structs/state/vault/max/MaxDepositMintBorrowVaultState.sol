// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewDepositVaultState} from "src/structs/state/vault/preview/PreviewDepositVaultState.sol";

/**
 * @title MaxDepositMintBorrowVaultState
 * @notice This struct needed for max deposit mint borrow vault calculations
 */
struct MaxDepositMintBorrowVaultState {
    PreviewDepositVaultState previewDepositVaultState;
    uint256 maxTotalAssetsInUnderlying;
    uint16 minProfitLtvDividend;
    uint16 minProfitLtvDivider;
}
