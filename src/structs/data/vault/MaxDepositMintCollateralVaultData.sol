// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewCollateralVaultData} from "src/structs/data/vault/PreviewCollateralVaultData.sol";

/**
 * @title MaxDepositMintCollateralVaultData
 * @notice This struct needed for max deposit mint collateral vault calculations
 */
struct MaxDepositMintCollateralVaultData {
    PreviewCollateralVaultData previewCollateralVaultData;
    uint256 realCollateral;
    uint256 realBorrow;
    uint256 maxTotalAssetsInUnderlying;
    uint16 minProfitLtvDividend;
    uint16 minProfitLtvDivider;
}
