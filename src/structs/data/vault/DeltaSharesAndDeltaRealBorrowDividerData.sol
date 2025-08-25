// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Cases} from "src/structs/data/vault/Cases.sol";

struct DeltaSharesAndDeltaRealBorrowDividerData {
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    int256 userFutureRewardBorrow;
    int256 futureBorrow;
    uint256 borrowSlippage;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    Cases cases;
}
