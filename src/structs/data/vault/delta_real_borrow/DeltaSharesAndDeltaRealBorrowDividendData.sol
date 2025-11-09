// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Cases} from "../common/Cases.sol";

/**
 * @title DeltaSharesAndDeltaRealBorrowDividendData
 * @notice This struct needed for delta shares and delta real borrow dividend calculations
 */
struct DeltaSharesAndDeltaRealBorrowDividendData {
    int256 borrow;
    int256 collateral;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    int256 userFutureRewardBorrow;
    int256 futureBorrow;
    uint256 borrowSlippage;
    int256 deltaRealBorrow;
    int256 deltaShares;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    Cases cases;
}
