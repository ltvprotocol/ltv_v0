// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Cases} from "../common/Cases.sol";

/**
 * @title DeltaSharesAndDeltaRealBorrowData
 * @notice This struct needed for delta shares and delta real borrow calculations
 */
struct DeltaSharesAndDeltaRealBorrowData {
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    int256 borrow;
    int256 collateral;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    int256 deltaShares;
    int256 deltaRealBorrow;
    int256 userFutureRewardBorrow;
    int256 futureBorrow;
    int256 futureCollateral;
    uint256 borrowSlippage;
    Cases cases;
}
