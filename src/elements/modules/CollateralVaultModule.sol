// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {DepositCollateral} from "../../public/vault/write/collateral/execute/DepositCollateral.sol";
import {MintCollateral} from "../../public/vault/write/collateral/execute/MintCollateral.sol";
import {RedeemCollateral} from "../../public/vault/write/collateral/execute/RedeemCollateral.sol";
import {WithdrawCollateral} from "../../public/vault/write/collateral/execute/WithdrawCollateral.sol";
import {ConvertToAssetsCollateral} from "../../public/vault/read/collateral/convert/ConvertToAssetsCollateral.sol";
import {ConvertToSharesCollateral} from "../../public/vault/read/collateral/convert/ConvertToSharesCollateral.sol";

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
    ConvertToSharesCollateral
{
    constructor() {
        _disableInitializers();
    }
}
