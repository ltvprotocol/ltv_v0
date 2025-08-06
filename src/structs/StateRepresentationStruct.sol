// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct StateRepresentationStruct {
    int256 futureBorrowAssets;
    int256 futureCollateralAssets;
    int256 futureRewardBorrowAssets;
    int256 futureRewardCollateralAssets;
    uint256 startAuction;
    uint256 baseTotalSupply;
    uint16 maxSafeLTVDividend;
    uint16 maxSafeLTVDivider;
    uint16 minProfitLTVDividend;
    uint16 minProfitLTVDivider;
    uint16 targetLTVDividend;
    uint16 targetLTVDivider;
    bool isVaultDeleveraged;
    uint256 lastSeenTokenPrice;
    uint16 maxGrowthFeeDividend;
    uint16 maxGrowthFeeDivider;
    uint256 maxTotalAssetsInUnderlying;
    bool isDepositDisabled;
    bool isWithdrawDisabled;
    bool isWhitelistActivated;
    uint16 maxDeleverageFeeDividend;
    uint16 maxDeleverageFeeDivider;
}
