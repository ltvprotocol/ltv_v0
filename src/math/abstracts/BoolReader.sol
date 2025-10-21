// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/constants/Constants.sol";

/**
 * @title BoolReader
 * @notice Contract contains common functionality for all bool reader functions.
 * It is used to retrieve vault boolean state. All the boolean configurations
 * take place only in administration part of the protocol.
 */
abstract contract BoolReader {
    /**
     * @notice implementation of isDepositDisabled
     */
    function _isDepositDisabled(uint8 boolSlot) internal pure returns (bool) {
        return _getBool(boolSlot, Constants.IS_DEPOSIT_DISABLED_BIT);
    }

    /**
     * @notice implementation of isVaultDeleveraged
     */
    function _isVaultDeleveraged(uint8 boolSlot) internal pure returns (bool) {
        return _getBool(boolSlot, Constants.IS_VAULT_DELEVERAGED_BIT);
    }

    /**
     * @notice implementation of isWhitelistActivated
     */
    function _isWhitelistActivated(uint8 boolSlot) internal pure returns (bool) {
        return _getBool(boolSlot, Constants.IS_WHITELIST_ACTIVATED_BIT);
    }

    /**
     * @notice implementation of isWithdrawDisabled
     */
    function _isWithdrawDisabled(uint8 boolSlot) internal pure returns (bool) {
        return _getBool(boolSlot, Constants.IS_WITHDRAW_DISABLED_BIT);
    }

    /**
     * @notice function to get bool value from bool slot for appropriate bit
     */
    function _getBool(uint8 boolSlot, uint8 bit) private pure returns (bool) {
        return boolSlot & (2 ** bit) != 0;
    }
}
