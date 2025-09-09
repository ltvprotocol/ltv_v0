// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AdministrationPublic} from "../../public/administration/AdministrationPublic.sol";
import {OnlyOwner} from "../../public/administration/OnlyOwner.sol";

contract AdministrationModule is AdministrationPublic, OnlyOwner {
    constructor() {
        _disableInitializers();
    }
}
