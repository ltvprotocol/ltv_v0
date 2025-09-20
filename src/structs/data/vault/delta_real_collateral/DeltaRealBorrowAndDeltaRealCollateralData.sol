// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Cases} from "src/structs/data/vault/common/Cases.sol";

/**
 * @title DeltaRealBorrowAndDeltaRealCollateralData
 * @notice This struct needed for delta real borrow and delta real collateral calculations
 */
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
