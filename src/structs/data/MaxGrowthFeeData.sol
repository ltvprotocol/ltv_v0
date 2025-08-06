// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct MaxGrowthFeeData {
    uint256 withdrawTotalAssets;
    uint16 maxGrowthFeeDividend;
    uint16 maxGrowthFeeDivider;
    uint256 supply;
    uint256 lastSeenTokenPrice;
}
