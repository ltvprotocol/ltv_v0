// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BoolReader} from "../../../math/abstracts/BoolReader.sol";

/**
 * @title GetVaultBoolState
 * @notice This contract is used to retrieve the boolean state of the vault.
 */
contract GetVaultBoolState is BoolReader {
    /**
     * @dev see IAdministrationModule.isDepositDisabled
     */
    function isDepositDisabled(uint8 boolSlot) public pure returns (bool) {
        return _isDepositDisabled(boolSlot);
    }

    /**
     * @dev see IAdministrationModule.isWithdrawDisabled
     */
    function isWithdrawDisabled(uint8 boolSlot) public pure returns (bool) {
        return _isWithdrawDisabled(boolSlot);
    }

    /**
     * @dev see IAdministrationModule.isWhitelistActivated
     */
    function isWhitelistActivated(uint8 boolSlot) public pure returns (bool) {
        return _isWhitelistActivated(boolSlot);
    }

    /**
     * @dev see IAdministrationModule.isVaultDeleveraged
     */
    function isVaultDeleveraged(uint8 boolSlot) public pure returns (bool) {
        return _isVaultDeleveraged(boolSlot);
    }

    /**
     * @dev see IAdministrationModule.isProtocolPaused
     */
    function isProtocolPaused(uint8 boolSlot) public pure returns (bool) {
        return _isProtocolPaused(boolSlot);
    }

    /**
     * @dev see IAdministrationModule.isSoftLiquidationEnabledForAnyone
     */
    function isSoftLiquidationEnabledForAnyone(uint8 boolSlot) public pure returns (bool) {
        return _isSoftLiquidationEnabledForAnyone(boolSlot);
    }
}
