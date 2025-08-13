// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

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
    uint16 targetLTVDividend;
    uint16 targetLTVDivider;
    int256 deltaRealCollateral;
    int256 deltaRealBorrow;
}
