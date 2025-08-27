// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Initialize} from "src/state_transition/Initialize.sol";

contract InitializeModule is Initialize {
    constructor() {
        _disableInitializers();
    }
}
