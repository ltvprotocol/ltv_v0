// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";
import {LTVState} from "src/states/LTVState.sol";

/**
 * @title AdministrationModifiers
 * @notice This contract contains modifiers for the administration part of the LTV protocol.
 * It checks if the caller is the governor, guardian, or emergency deleverager.
 */
abstract contract AdministrationModifiers is LTVState, IAdministrationErrors {
    /**
     * @dev modifier to check if the caller is the governor
     */
    modifier onlyGovernor() {
        _checkGovernor();
        _;
    }

    /**
     * @dev modifier to check if the caller is the guardian
     */
    modifier onlyGuardian() {
        _checkGuardian();
        _;
    }

    /**
     * @dev modifier to check if the caller is the emergency deleverager
     */
    modifier onlyEmergencyDeleverager() {
        _checkEmergencyDeleverager();
        _;
    }

    /**
     * @dev checks if the caller is the governor
     */
    function _checkGovernor() internal view {
        if (msg.sender != governor) revert OnlyGovernorInvalidCaller(msg.sender);
    }

    /**
     * @dev checks if the caller is the guardian
     */
    function _checkGuardian() internal view {
        if (msg.sender != guardian) revert OnlyGuardianInvalidCaller(msg.sender);
    }

    /**
     * @dev checks if the caller is the emergency deleverager
     */
    function _checkEmergencyDeleverager() internal view {
        if (msg.sender != emergencyDeleverager) revert OnlyEmergencyDeleveragerInvalidCaller(msg.sender);
    }
}
