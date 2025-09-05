// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewLowLevelRebalanceState} from "src/structs/state/low_level/PreviewLowLevelRebalanceState.sol";

/**
 * @title ExecuteLowLevelRebalanceState
 * @notice This struct needed for execute low level rebalance calculations
 */
struct ExecuteLowLevelRebalanceState {
    PreviewLowLevelRebalanceState previewLowLevelRebalanceState;
    uint256 maxTotalAssetsInUnderlying;
}
