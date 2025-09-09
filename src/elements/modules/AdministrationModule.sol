// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AdministrationPublic} from "../../public/administration/AdministrationPublic.sol";
import {OnlyOwner} from "../../public/administration/OnlyOwner.sol";
import {OnlyGuardian} from "../../public/administration/OnlyGuardian.sol";
import {OnlyGovernor} from "../../public/administration/OnlyGovernor.sol";

contract AdministrationModule is AdministrationPublic, OnlyOwner, OnlyGuardian, OnlyGovernor {
    constructor() {
        _disableInitializers();
    }
}
