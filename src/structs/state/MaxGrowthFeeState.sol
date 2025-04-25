// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./vault/TotalAssetsState.sol";

struct MaxGrowthFeeState {
    TotalAssetsState totalAssetsState;
    uint256 maxGrowthFee;
    uint256 supply;
    uint256 lastSeenTokenPrice;
} 