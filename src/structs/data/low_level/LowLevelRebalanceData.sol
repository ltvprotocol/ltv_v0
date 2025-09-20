// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title LowLevelRebalanceData
 * @notice This struct needed for low level rebalance calculations
 */
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
    uint8 collateralTokenDecimals;
    uint256 borrowPrice;
    uint8 borrowTokenDecimals;
    uint256 supplyAfterFee;
    uint256 totalAssets;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    uint256 withdrawTotalAssets;
}
