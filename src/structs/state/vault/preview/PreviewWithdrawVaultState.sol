// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "../../common/MaxGrowthFeeState.sol";

/**
 * @title PreviewWithdrawVaultState
 * @notice This struct needed for preview withdraw vault calculations
 */
struct PreviewWithdrawVaultState {
    MaxGrowthFeeState maxGrowthFeeState;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    uint56 startAuction;
    uint24 auctionDuration;
    uint56 blockNumber;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
}
