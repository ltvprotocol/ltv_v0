// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Cases} from "../common/Cases.sol";

/**
 * @title DeltaRealBorrowAndDeltaRealCollateralDividerData
 * @notice This struct needed for delta real borrow and delta real collateral divider calculations
 */
struct DeltaRealBorrowAndDeltaRealCollateralDividerData {
    Cases cases;
    int256 futureCollateral;
    int256 futureBorrow;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
    int256 collateral;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    int256 userFutureRewardBorrow;
    int256 userFutureRewardCollateral;
}
