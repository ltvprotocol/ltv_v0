// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/structs/state/MaxGrowthFeeState.sol';

struct MaxLowLevelRebalanceSharesState {
    MaxGrowthFeeState maxGrowthFeeState;
    uint256 maxTotalAssetsInUnderlying;
}

struct MaxLowLevelRebalanceSharesData {
    uint256 realCollateral;
    uint256 realBorrow;
    uint256 maxTotalAssetsInUnderlying;
    uint256 supplyAfterFee;
    uint256 borrowPrice;
    uint256 depositTotalAssets;
}

struct MaxLowLevelRebalanceBorrowStateData {
    uint256 realBorrowAssets;
    uint256 maxTotalAssetsInUnderlying;
    uint256 targetLTV;
    uint256 borrowPrice;
} 
struct MaxLowLevelRebalanceCollateralStateData {
    uint256 realCollateralAssets;
    uint256 maxTotalAssetsInUnderlying;
    uint256 targetLTV;
    uint256 collateralPrice;
}

struct PreviewLowLevelRebalanceState {
    MaxGrowthFeeState maxGrowthFeeState;
    uint128 targetLTV;
    uint256 blockNumber;
    uint256 startAuction;
}

struct LowLevelRebalanceData {
    int256 futureCollateral;
    int256 futureBorrow;
    int256 realCollateral;
    int256 realBorrow;
    int256 userFutureRewardCollateral;
    int256 userFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    int256 protocolFutureRewardBorrow;
    uint256 collateralPrice;
    uint256 borrowPrice;
    uint256 supplyAfterFee;
    uint256 totalAssets;
    uint128 targetLTV;
}

struct ExecuteLowLevelRebalanceState {
    PreviewLowLevelRebalanceState previewLowLevelRebalanceState;
    uint256 maxTotalAssetsInUnderlying;
}