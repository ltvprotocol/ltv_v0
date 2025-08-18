// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";
import {LTVState} from "src/states/LTVState.sol";

abstract contract FunctionStopperModifier is LTVState, OwnableUpgradeable, IAdministrationErrors {
    modifier isFunctionAllowed() {
        _checkFunctionAllowed();
        _;
    }

    function _checkFunctionAllowed() private view {
        require(!_isFunctionDisabled[msg.sig], FunctionStopped(msg.sig));
    }
}
