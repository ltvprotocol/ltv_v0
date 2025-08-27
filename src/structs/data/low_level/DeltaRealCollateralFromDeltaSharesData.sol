// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct DeltaRealCollateralFromDeltaSharesData {
    int256 deltaShares;
    int256 futureCollateral;
    int256 userFutureRewardCollateral;
    int256 realCollateral;
    int256 realBorrow;
    int256 futureBorrow;
    int256 userFutureRewardBorrow;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
}
