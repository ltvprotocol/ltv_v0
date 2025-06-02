// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct StateRepresentationStruct {
    int256 futureBorrowAssets;
    int256 futureCollateralAssets;
    int256 futureRewardBorrowAssets;
    int256 futureRewardCollateralAssets;
    uint256 startAuction;
    uint256 baseTotalSupply;
    uint128 maxSafeLTV;
    uint128 minProfitLTV;
    uint128 targetLTV;
    bool isVaultDeleveraged;
    uint256 lastSeenTokenPrice;
    uint256 maxGrowthFee;
    uint256 maxTotalAssetsInUnderlying;
    bool isDepositDisabled;
    bool isWithdrawDisabled;
    bool isWhitelistActivated;
    uint256 maxDeleverageFee;
}
