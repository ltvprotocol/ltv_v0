// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Cases} from "../data/vault/common/Cases.sol";

/**
 * @title DeltaFuture
 * @notice This struct represents changes of future state after vault calculations
 */
struct DeltaFuture {
    int256 deltaFutureCollateral;
    int256 deltaFutureBorrow;
    int256 deltaProtocolFutureRewardCollateral;
    int256 deltaUserFutureRewardCollateral;
    int256 deltaFuturePaymentCollateral;
    int256 deltaProtocolFutureRewardBorrow;
    int256 deltaUserFutureRewardBorrow;
    int256 deltaFuturePaymentBorrow;
    Cases cases;
}
