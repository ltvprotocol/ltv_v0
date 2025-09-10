// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {DepositCollateral} from "src/public/vault/collateral/execute/DepositCollateral.sol";
import {MintCollateral} from "src/public/vault/collateral/execute/MintCollateral.sol";
import {RedeemCollateral} from "src/public/vault/collateral/execute/RedeemCollateral.sol";
import {WithdrawCollateral} from "src/public/vault/collateral/execute/WithdrawCollateral.sol";
import {ConvertToAssetsCollateral} from "src/public/vault/collateral/convert/ConvertToAssetsCollateral.sol";
import {ConvertToSharesCollateral} from "src/public/vault/collateral/convert/ConvertToSharesCollateral.sol";
import {AssetCollateral} from "src/public/vault/collateral/AssetCollateral.sol";

/**
 * @title CollateralVaultModule
 * @notice Collateral vault module for LTV protocol
 */
contract CollateralVaultModule is
    DepositCollateral,
    MintCollateral,
    RedeemCollateral,
    WithdrawCollateral,
    ConvertToAssetsCollateral,
    ConvertToSharesCollateral,
    AssetCollateral
{
    constructor() {
        _disableInitializers();
    }
}
