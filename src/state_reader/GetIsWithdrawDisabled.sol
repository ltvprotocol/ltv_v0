    // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../states/LTVState.sol";

contract GetIsWithdrawDisabled is LTVState {
    function isWithdrawDisabled() public view returns (bool) {
        return boolSlot & (2 ** IS_WITHDRAW_DISABLED_BIT) != 0;
    }
}
