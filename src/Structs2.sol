// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct TotalAssetsState {
    uint256 realCollateralAssets;
    uint256 realBorrowAssets;
    int256 futureBorrowAssets;
    int256 futureCollateralAssets;
    int256 futureRewardBorrowAssets;
    int256 futureRewardCollateralAssets;
    uint256 borrowPrice;
    uint256 collateralPrice;
}

struct TotalAssetsData {
    int256 collateral;
    int256 borrow;
    uint256 borrowPrice;
}

struct MaxGrowthFeeState {
    TotalAssetsState totalAssetsState;
    uint256 maxGrowthFee;
    uint256 supply;
    uint256 lastSeenTokenPrice;
}

struct MaxGrowthFeeData {
    uint256 totalAssets;
    uint256 maxGrowthFee;
    uint256 supply;
    uint256 lastSeenTokenPrice;
}

struct VaultState {
    MaxGrowthFeeState maxGrowthFeeState;
    uint256 targetLTV;
    uint256 startAuction;
    uint256 blockNumber;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
    uint256 maxTotalAssetsInUnderlying;
    bool isDeposit;
}

struct VaultData {
    int256 collateral;
    int256 borrow;
    int256 futureBorrow;
    int256 futureCollateral;
    int256 userFutureRewardBorrow;
    int256 userFutureRewardCollateral;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;

    uint256 totalAssets;
    uint256 borrowPrice;
    uint256 collateralPrice;
    uint256 supplyAfterFee;
    uint256 targetLTV;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
    uint256 maxTotalAssetsInUnderlying; 
}

struct MintRedeemData {
    int256 collateral;
    int256 borrow;
    int256 futureBorrow;
    int256 futureCollateral;
    int256 userFutureRewardBorrow;
    int256 userFutureRewardCollateral;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
    uint256 targetLTV;
    uint256 deltaShares;
    bool isBorrow;
}

struct DeltaSharesAndDeltaRealCollateralData {
    uint256 targetLTV;
    int256 borrow;
    int256 collateral;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    int256 deltaShares;
    int256 userFutureRewardCollateral;
    int256 futureCollateral;
    int256 collateralSlippage;
}

struct DeltaSharesAndDeltaRealBorrowData {
    uint256 targetLTV;
    int256 borrow;
    int256 collateral;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    int256 deltaShares;
    int256 userFutureRewardBorrow;
    int256 futureBorrow;
    int256 borrowSlippage;
}