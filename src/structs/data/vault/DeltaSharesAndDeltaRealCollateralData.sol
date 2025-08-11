// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./Cases.sol";

struct DeltaSharesAndDeltaRealCollateralData {
    uint16 targetLTVDividend;
    uint16 targetLTVDivider;
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
