// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";
import {LTVState} from "src/states/LTVState.sol";

abstract contract AdministrationModifiers is LTVState, IAdministrationErrors {
    modifier onlyGovernor() {
        _checkGovernor();
        _;
    }

    modifier onlyGuardian() {
        _checkGuardian();
        _;
    }

    modifier onlyEmergencyDeleverager() {
        _checkEmergencyDeleverager();
        _;
    }

    function _checkGovernor() internal view {
        if (msg.sender != governor) revert OnlyGovernorInvalidCaller(msg.sender);
    }

    function _checkGuardian() internal view {
        if (msg.sender != guardian) revert OnlyGuardianInvalidCaller(msg.sender);
    }

    function _checkEmergencyDeleverager() internal view {
        if (msg.sender != emergencyDeleverager) revert OnlyEmergencyDeleveragerInvalidCaller(msg.sender);
    }
}
