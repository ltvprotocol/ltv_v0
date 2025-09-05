// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title DepositWithdrawData
 * @notice This struct needed for deposit and withdraw calculations
 */
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
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    int256 deltaRealCollateral;
    int256 deltaRealBorrow;
}
