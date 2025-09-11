// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "src/structs/state/common/MaxGrowthFeeState.sol";

/**
 * @title PreviewDepositVaultState
 * @notice This struct needed for preview deposit vault calculations
 */
struct PreviewDepositVaultState {
    MaxGrowthFeeState maxGrowthFeeState;
    uint256 depositRealBorrowAssets;
    uint256 depositRealCollateralAssets;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    uint56 startAuction;
    uint24 auctionDuration;
    uint56 blockNumber;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
}
