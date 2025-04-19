// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct Cases {
    uint8 cna;
    uint8 cmcb;
    uint8 cmbc;
    uint8 cecb;
    uint8 cebc;
    uint8 ceccb;
    uint8 cecbc;
    uint8 ncase;
}

struct DeltaFuture {
    int256 deltaFutureCollateral;
    int256 deltaFutureBorrow;
    int256 deltaProtocolFutureRewardCollateral;
    int256 deltaUserFutureRewardCollateral;
    int256 deltaFuturePaymentCollateral;
    int256 deltaProtocolFutureRewardBorrow;
    int256 deltaUserFutureRewardBorrow;
    int256 deltaFuturePaymentBorrow;
}

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
    uint128 targetLTV;
    uint256 startAuction;
    uint256 blockNumber;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
    uint256 maxTotalAssetsInUnderlying;
    bool isDeposit;
}

struct DepositMintState {
    VaultState vaultState;
    uint256 minProfitLTV;
}

struct WithdrawRedeemState {
    VaultState vaultState;
    uint256 maxSafeLTV;
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
    uint128 targetLTV;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
    uint256 maxTotalAssetsInUnderlying;
}

struct DepositMintData {
    VaultData vaultData;
    uint256 minProfitLTV;
}

struct WithdrawRedeemData {
    VaultData vaultData;
    uint256 maxSafeLTV;
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
    uint128 targetLTV;
    int256 deltaShares;
    bool isBorrow;
}

struct DepositWithdrawData {
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
    uint128 targetLTV;
    int256 deltaRealCollateral;
    int256 deltaRealBorrow;
}

struct DeltaSharesAndDeltaRealCollateralData {
    uint128 targetLTV;
    int256 borrow;
    int256 collateral;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    int256 deltaShares;
    int256 deltaRealCollateral;
    int256 userFutureRewardCollateral;
    int256 futureCollateral;
    uint256 collateralSlippage;
    Cases cases;
}

struct DeltaSharesAndDeltaRealBorrowData {
    uint128 targetLTV;
    int256 borrow;
    int256 collateral;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    int256 deltaShares;
    int256 deltaRealBorrow;
    int256 userFutureRewardBorrow;
    int256 futureBorrow;
    uint256 borrowSlippage;
    Cases cases;
}

struct DeltaRealBorrowAndDeltaRealCollateralData {
    int256 deltaRealCollateral;
    int256 deltaRealBorrow;
    uint128 targetLTV;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
    int256 collateral;
    int256 borrow;
    int256 futureBorrow;
    int256 futureCollateral;
    int256 userFutureRewardBorrow;
    int256 userFutureRewardCollateral;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    Cases cases;
}