// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewWithdrawVaultState} from "src/structs/state/vault/PreviewWithdrawVaultState.sol";

/**
 * @title MaxWithdrawRedeemCollateralVaultState
 * @notice This struct needed for max withdraw redeem collateral vault calculations
 */
struct MaxWithdrawRedeemCollateralVaultState {
    PreviewWithdrawVaultState previewWithdrawVaultState;
    uint16 maxSafeLtvDividend;
    uint16 maxSafeLtvDivider;
    uint256 ownerBalance;
}
