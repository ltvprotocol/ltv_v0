// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../states/LTVState.sol";

contract GetIsVaultDeleveraged is LTVState {
    function isVaultDeleveraged() public view returns (bool) {
        return boolSlot & (2 ** IS_VAULT_DELEVERAGED_BIT) != 0;
    }
}
