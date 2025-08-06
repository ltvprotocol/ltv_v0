// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct NextStepData {
    int256 futureBorrow;
    int256 futureCollateral;
    int256 futureRewardBorrow;
    int256 futureRewardCollateral;
    int256 deltaFutureBorrow;
    int256 deltaFutureCollateral;
    int256 deltaFuturePaymentBorrow;
    int256 deltaUserFutureRewardBorrow;
    int256 deltaProtocolFutureRewardBorrow;
    int256 deltaFuturePaymentCollateral;
    int256 deltaUserFutureRewardCollateral;
    int256 deltaProtocolFutureRewardCollateral;
    uint56 blockNumber;
    uint24 auctionStep;
}
