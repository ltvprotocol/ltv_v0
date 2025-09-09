// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {OnlyEmergencyDeleverager} from "../../public/administration/OnlyEmergencyDeleverager.sol";
import {OnlyOwner} from "../../public/administration/OnlyOwner.sol";
import {OnlyGuardian} from "../../public/administration/OnlyGuardian.sol";
import {OnlyGovernor} from "../../public/administration/OnlyGovernor.sol";

contract AdministrationModule is OnlyEmergencyDeleverager, OnlyOwner, OnlyGuardian, OnlyGovernor {
    constructor() {
        _disableInitializers();
    }
}
