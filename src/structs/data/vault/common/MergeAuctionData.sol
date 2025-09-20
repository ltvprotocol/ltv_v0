// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title MergeAuctionData
 * @notice This struct needed for merge auction calculations
 */
struct MergeAuctionData {
    int256 futureBorrow;
    int256 futureCollateral;
    int256 futureRewardBorrow;
    int256 futureRewardCollateral;
    int256 deltaFutureBorrow;
    int256 deltaFutureCollateral;
    uint24 auctionStep;
    int256 deltaFuturePaymentBorrow;
    int256 deltaFuturePaymentCollateral;
    uint56 blockNumber;
}
