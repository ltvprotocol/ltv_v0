// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

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