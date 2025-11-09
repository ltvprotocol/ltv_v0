// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Cases} from "../common/Cases.sol";

/**
 * @title DeltaSharesAndDeltaRealCollateralDividendData
 * @notice This struct needed for delta shares and delta real collateral dividend calculations
 */
struct DeltaSharesAndDeltaRealCollateralDividendData {
    Cases cases;
    int256 borrow;
    int256 deltaRealCollateral;
    int256 userFutureRewardCollateral;
    int256 futureCollateral;
    uint256 collateralSlippage;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    int256 deltaShares;
    int256 collateral;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
}
