// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./PreviewLowLevelRebalanceState.sol";

struct ExecuteLowLevelRebalanceState {
    PreviewLowLevelRebalanceState previewLowLevelRebalanceState;
    uint256 maxTotalAssetsInUnderlying;
}
