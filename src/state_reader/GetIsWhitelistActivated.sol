    // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../states/LTVState.sol";

contract GetIsWhitelistActivated is LTVState {
    function isWhitelistActivated() public view returns (bool) {
        return boolSlot & (2 ** IS_WHITELIST_ACTIVATED_BIT) != 0;
    }
}
