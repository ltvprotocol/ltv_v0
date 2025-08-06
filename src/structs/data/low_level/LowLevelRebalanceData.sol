// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct LowLevelRebalanceData {
    int256 futureCollateral;
    int256 futureBorrow;
    int256 realCollateral;
    int256 realBorrow;
    int256 userFutureRewardCollateral;
    int256 userFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    int256 protocolFutureRewardBorrow;
    uint256 collateralPrice;
    uint256 borrowPrice;
    uint256 supplyAfterFee;
    uint256 totalAssets;
    uint16 targetLTVDividend;
    uint16 targetLTVDivider;
    uint256 withdrawTotalAssets;
}
