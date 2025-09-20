// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title MaxGrowthFeeData
 * @notice This struct needed for max growth fee calculations
 */
struct MaxGrowthFeeData {
    uint256 withdrawTotalAssets;
    uint16 maxGrowthFeeDividend;
    uint16 maxGrowthFeeDivider;
    uint256 supply;
    uint256 lastSeenTokenPrice;
}
