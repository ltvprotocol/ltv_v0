// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../states/LTVState.sol";

contract GetIsDepositDisabled is LTVState {
    function isDepositDisabled() public view returns (bool) {
        return boolSlot & (2 ** IS_DEPOSIT_DISABLED_BIT) != 0;
    }
}
