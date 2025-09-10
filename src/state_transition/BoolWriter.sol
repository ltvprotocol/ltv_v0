// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "src/states/LTVState.sol";

/**
 * @title BoolWriter
 * @notice contract contains functionality to write bool to the state slot
 */
contract BoolWriter is LTVState {
    /**
     * @dev writes bool to the state slot
     */
    function setBool(uint8 bit, bool value) internal {
        if (value) {
            boolSlot |= uint8(2 ** bit);
        } else {
            boolSlot &= ~uint8(2 ** bit);
        }
    }
}
