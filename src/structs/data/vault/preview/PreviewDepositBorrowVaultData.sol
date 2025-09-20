// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title PreviewDepositBorrowVaultData
 * @notice This struct needed for preview deposit borrow vault calculations
 */
struct PreviewDepositBorrowVaultData {
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
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    uint256 borrowPrice;
    uint8 borrowTokenDecimals;
    uint256 supplyAfterFee;
    uint256 withdrawTotalAssets;
    uint256 depositTotalAssets;
}
