// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Initialize} from "src/state_transition/Initialize.sol";

/**
 * @title InitializeModule
 * @notice Initialize module for LTV protocol
 */
contract InitializeModule is Initialize {
    constructor() {
        _disableInitializers();
    }
}
