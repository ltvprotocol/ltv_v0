// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "src/structs/state/common/MaxGrowthFeeState.sol";

struct MaxLowLevelRebalanceSharesState {
    MaxGrowthFeeState maxGrowthFeeState;
    uint256 maxTotalAssetsInUnderlying;
}
