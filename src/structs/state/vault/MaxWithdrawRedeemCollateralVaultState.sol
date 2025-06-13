// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./PreviewWithdrawVaultState.sol";

struct MaxWithdrawRedeemCollateralVaultState {
    PreviewWithdrawVaultState previewWithdrawVaultState;
    uint256 maxSafeLTV;
    uint256 ownerBalance;
}
