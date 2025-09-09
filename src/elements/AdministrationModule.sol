// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AdministrationPublic} from "src/public/AdministrationPublic.sol";

/**
 * @title AdministrationModule
 * @notice Administration module for LTV protocol
 */
contract AdministrationModule is AdministrationPublic {
    constructor() {
        _disableInitializers();
    }
}
