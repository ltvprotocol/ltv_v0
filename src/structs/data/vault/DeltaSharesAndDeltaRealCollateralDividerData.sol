// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Cases} from "src/structs/data/vault/Cases.sol";

struct DeltaSharesAndDeltaRealCollateralDividerData {
    Cases cases;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    int256 userFutureRewardCollateral;
    int256 futureCollateral;
    uint256 collateralSlippage;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
}
