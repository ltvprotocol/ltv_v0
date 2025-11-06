// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewDepositVaultState} from "../preview/PreviewDepositVaultState.sol";

/**
 * @title MaxDepositMintCollateralVaultState
 * @notice This struct needed for max deposit mint collateral vault calculations
 */
struct MaxDepositMintCollateralVaultState {
    PreviewDepositVaultState previewDepositVaultState;
    uint256 maxTotalAssetsInUnderlying;
    uint16 minProfitLtvDividend;
    uint16 minProfitLtvDivider;
}
