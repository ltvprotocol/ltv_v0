// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title PreviewCollateralVaultData
 * @notice This struct needed for preview functions of collateral vault calculations
 */
struct PreviewCollateralVaultData {
    int256 collateral;
    int256 borrow;
    int256 futureBorrow;
    int256 futureCollateral;
    int256 userFutureRewardBorrow;
    int256 userFutureRewardCollateral;
    int256 protocolFutureRewardBorrow;
    int256 protocolFutureRewardCollateral;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    uint256 collateralPrice;
    uint8 collateralTokenDecimals;
    uint256 supplyAfterFee;
    uint256 totalAssetsCollateral;
    uint256 withdrawTotalAssets;
}
