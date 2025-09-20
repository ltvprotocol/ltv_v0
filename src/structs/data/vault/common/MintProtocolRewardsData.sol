// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title MintProtocolRewardsData
 * @notice This struct needed for mint protocol rewards calculations
 */
struct MintProtocolRewardsData {
    int256 deltaProtocolFutureRewardBorrow;
    int256 deltaProtocolFutureRewardCollateral;
    uint256 supply;
    uint256 totalAppropriateAssets;
    uint256 assetPrice;
    uint8 assetTokenDecimals;
}
