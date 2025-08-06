// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./Cases.sol";

struct DeltaRealBorrowAndDeltaRealCollateralData {
    int256 deltaRealCollateral;
    int256 deltaRealBorrow;
    uint16 targetLTVDividend;
    uint16 targetLTVDivider;
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
