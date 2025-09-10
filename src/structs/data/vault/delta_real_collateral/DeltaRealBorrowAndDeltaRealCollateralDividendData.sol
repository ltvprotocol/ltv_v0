// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Cases} from "src/structs/data/vault/common/Cases.sol";

/**
 * @title DeltaRealBorrowAndDeltaRealCollateralDividendData
 * @notice This struct needed for delta real borrow and delta real collateral dividend calculations
 */
struct DeltaRealBorrowAndDeltaRealCollateralDividendData {
    Cases cases;
    int256 borrow;
    int256 deltaRealBorrow;
    int256 futureCollateral;
    int256 futureBorrow;
    int256 userFutureRewardBorrow;
    int256 userFutureRewardCollateral;
    uint256 borrowSlippage;
    uint256 collateralSlippage;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    int256 collateral;
    int256 deltaRealCollateral;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
}
