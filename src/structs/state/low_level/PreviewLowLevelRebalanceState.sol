// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "src/structs/state/MaxGrowthFeeState.sol";

/**
 * @title PreviewLowLevelRebalanceState
 * @notice This struct needed for preview low level rebalance calculations
 */
struct PreviewLowLevelRebalanceState {
    MaxGrowthFeeState maxGrowthFeeState;
    uint256 depositRealBorrowAssets;
    uint256 depositRealCollateralAssets;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    uint56 blockNumber;
    uint56 startAuction;
    uint24 auctionDuration;
}
