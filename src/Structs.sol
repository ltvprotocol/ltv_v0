// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct Prices {
    uint256 borrow;
    uint256 collateral;
    uint256 borrowSlippage;
    uint256 collateralSlippage;
}

struct ConvertedAssets {
    int256 borrow;
    int256 collateral;
    int256 realBorrow;
    int256 realCollateral;
    int256 futureBorrow;
    int256 futureCollateral;
    int256 futureRewardBorrow;
    int256 futureRewardCollateral;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    int256 userFutureRewardBorrow;
    int256 userFutureRewardCollateral;
    int256 auctionStep;
}

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

struct NextState {
    int256 futureBorrow;
    int256 futureCollateral;
    int256 futureRewardBorrow;
    int256 futureRewardCollateral;
    uint256 startAuction;
    bool merge;
}