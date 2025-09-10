// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewWithdrawVaultState} from "src/structs/state/vault/preview/PreviewWithdrawVaultState.sol";

/**
 * @title MaxWithdrawRedeemBorrowVaultState
 * @notice This struct needed for max withdraw redeem borrow vault calculations
 */
struct MaxWithdrawRedeemBorrowVaultState {
    PreviewWithdrawVaultState previewWithdrawVaultState;
    uint16 maxSafeLtvDividend;
    uint16 maxSafeLtvDivider;
    uint256 ownerBalance;
}
