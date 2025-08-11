// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../states/LTVState.sol";
import "../Constants.sol";

contract BoolReader is LTVState {
    function isDepositDisabled() public view returns (bool) {
        return _getBool(Constants.IS_DEPOSIT_DISABLED_BIT);
    }

    function isVaultDeleveraged() public view returns (bool) {
        return _getBool(Constants.IS_VAULT_DELEVERAGED_BIT);
    }

    function isWhitelistActivated() public view returns (bool) {
        return _getBool(Constants.IS_WHITELIST_ACTIVATED_BIT);
    }

    function isWithdrawDisabled() public view returns (bool) {
        return _getBool(Constants.IS_WITHDRAW_DISABLED_BIT);
    }

    function _getBool(uint256 bit) private view returns (bool) {
        return boolSlot & (2 ** bit) != 0;
    }
}
