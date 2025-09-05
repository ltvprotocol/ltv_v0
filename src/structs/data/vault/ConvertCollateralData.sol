// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;
/**
 * @title ConvertCollateralData
 * @notice This struct needed for convert collateral calculations
 */

struct ConvertCollateralData {
    uint256 totalAssetsCollateral;
    uint256 supplyAfterFee;
}
