// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct MaxGrowthFeeData {
    uint256 withdrawTotalAssets;
    uint256 maxGrowthFee;
    uint256 supply;
    uint256 lastSeenTokenPrice;
} 