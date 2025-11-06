// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Cases} from "../common/Cases.sol";

/**
 * @title DeltaSharesAndDeltaRealBorrowDividerData
 * @notice This struct needed for delta shares and delta real borrow divider calculations
 */
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
