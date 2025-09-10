// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {OnlyEmergencyDeleverager} from "../../public/administration/write/OnlyEmergencyDeleverager.sol";
import {OnlyOwner} from "../../public/administration/write/OnlyOwner.sol";
import {OnlyGuardian} from "../../public/administration/write/OnlyGuardian.sol";
import {OnlyGovernor} from "../../public/administration/write/OnlyGovernor.sol";
import {GetVaultBoolState} from "../../public/administration/read/GetVaultBoolState.sol";

/**
 * @title AdministrationModule
 * @notice Administration module for LTV protocol
 */
contract AdministrationModule is OnlyEmergencyDeleverager, OnlyOwner, OnlyGuardian, OnlyGovernor, GetVaultBoolState {
    constructor() {
        _disableInitializers();
    }
}
