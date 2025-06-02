// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./PreviewVaultState.sol";

struct MaxWithdrawRedeemBorrowVaultState {
    PreviewVaultState previewVaultState;
    uint256 maxSafeLTV;
    uint256 ownerBalance;
}
