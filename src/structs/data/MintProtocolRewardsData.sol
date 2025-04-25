// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct MintProtocolRewardsData {
    int256 deltaProtocolFutureRewardBorrow;
    int256 deltaProtocolFutureRewardCollateral;
    uint256 supply;
    uint256 totalAppropriateAssets;
    uint256 assetPrice;
} 