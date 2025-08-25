// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Cases} from "src/structs/data/vault/Cases.sol";

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
