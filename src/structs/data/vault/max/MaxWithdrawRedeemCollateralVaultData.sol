// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewCollateralVaultData} from "../preview/PreviewCollateralVaultData.sol";

/**
 * @title MaxWithdrawRedeemCollateralVaultData
 * @notice This struct needed for max withdraw redeem collateral vault calculations
 */
struct MaxWithdrawRedeemCollateralVaultData {
    PreviewCollateralVaultData previewCollateralVaultData;
    uint256 realCollateral;
    uint256 realBorrow;
    uint16 maxSafeLtvDividend;
    uint16 maxSafeLtvDivider;
    uint256 ownerBalance;
}
