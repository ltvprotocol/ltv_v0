// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {LTVState} from "src/states/LTVState.sol";

/**
 * @title BoolReader
 * @notice contract contains functionality to retrieve boolean state flags
 * for various vault operations and configurations
 */
contract BoolReader is LTVState {
    /**
     * @dev see ILTV.isDepositDisabled
     */
    function isDepositDisabled() public view returns (bool) {
        return _getBool(Constants.IS_DEPOSIT_DISABLED_BIT);
    }

    /**
     * @dev see ILTV.isVaultDeleveraged
     */
    function isVaultDeleveraged() public view returns (bool) {
        return _getBool(Constants.IS_VAULT_DELEVERAGED_BIT);
    }

    /**
     * @dev see ILTV.isWhitelistActivated
     */
    function isWhitelistActivated() public view returns (bool) {
        return _getBool(Constants.IS_WHITELIST_ACTIVATED_BIT);
    }

    /**
     * @dev see ILTV.isWithdrawDisabled
     */
    function isWithdrawDisabled() public view returns (bool) {
        return _getBool(Constants.IS_WITHDRAW_DISABLED_BIT);
    }

    /**
     * @dev function to unwrap bool from slot
     */
    function _getBool(uint256 bit) private view returns (bool) {
        return boolSlot & (2 ** bit) != 0;
    }
}
