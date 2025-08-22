// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Cases} from "src/structs/data/vault/Cases.sol";

struct DeltaRealBorrowAndDeltaRealCollateralData {
    int256 deltaRealCollateral;
    int256 deltaRealBorrow;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
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

struct DividendData {
    Cases cases;
    int256 borrow;
    int256 deltaRealBorrow;
    int256 futureCollateral;
    int256 futureBorrow;
    int256 userFutureRewardBorrow;
    int256 userFutureRewardCollateral;
    uint256 borrowSlippage;
    uint256 collateralSlippage;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    int256 collateral;
    int256 deltaRealCollateral;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
}

struct DividerData {
    Cases cases;
    int256 futureCollateral;
    int256 futureBorrow;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
    int256 collateral;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    int256 userFutureRewardBorrow;
    int256 userFutureRewardCollateral;
}
