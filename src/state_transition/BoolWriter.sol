// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../states/LTVState.sol";

contract BoolWriter is LTVState {
    function setBool(uint8 bit, bool value) internal {
        if (value) {
            boolSlot |= uint8(2 ** bit);
        } else {
            boolSlot &= ~uint8(2 ** bit);
        }
    }
}
