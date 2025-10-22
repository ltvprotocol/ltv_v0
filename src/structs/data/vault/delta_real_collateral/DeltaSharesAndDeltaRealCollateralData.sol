// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Cases} from "src/structs/data/vault/common/Cases.sol";

/**
 * @title DeltaSharesAndDeltaRealCollateralData
 * @notice This struct needed for delta shares and delta real collateral calculations
 */
struct DeltaSharesAndDeltaRealCollateralData {
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    int256 borrow;
    int256 collateral;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    int256 deltaShares;
    int256 deltaRealCollateral;
    int256 userFutureRewardCollateral;
    int256 futureCollateral;
    int256 futureBorrow;
    uint256 collateralSlippage;
    Cases cases;
}
