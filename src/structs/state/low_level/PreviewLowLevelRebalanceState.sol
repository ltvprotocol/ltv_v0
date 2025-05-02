// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/structs/state/MaxGrowthFeeState.sol';

struct PreviewLowLevelRebalanceState {
    MaxGrowthFeeState maxGrowthFeeState;
    uint128 targetLTV;
    uint256 blockNumber;
    uint256 startAuction;
} 