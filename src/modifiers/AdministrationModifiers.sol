// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IAdministrationErrors} from "../errors/IAdministrationErrors.sol";
import {LTVState} from "../states/LTVState.sol";
import {BoolReader} from "../math/abstracts/BoolReader.sol";

/**
 * @title AdministrationModifiers
 * @notice This contract contains modifiers for the administration part of the LTV protocol.
 * It checks if the caller is the governor, guardian, or emergency deleverager.
 */
abstract contract AdministrationModifiers is LTVState, BoolReader, IAdministrationErrors {
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
     * @dev modifier to check if the caller is the emergency deleverager or anyone if enabled
     */
    modifier onlyEmergencyDeleveragerOrAnyone() {
        _checkEmergencyDeleveragerOrAnyone();
        _;
    }

    /**
     * @dev checks if the caller is the governor
     */
    function _checkGovernor() internal view {
        require(msg.sender == governor, OnlyGovernorInvalidCaller(msg.sender));
    }

    /**
     * @dev checks if the caller is the guardian
     */
    function _checkGuardian() internal view {
        require(msg.sender == guardian, OnlyGuardianInvalidCaller(msg.sender));
    }

    /**
     * @dev checks if the caller is the emergency deleverager
     */
    function _checkEmergencyDeleverager() internal view {
        require(msg.sender == emergencyDeleverager, OnlyEmergencyDeleveragerInvalidCaller(msg.sender));
    }

    /**
     * @dev checks if the caller is the emergency deleverager or anyone
     */
    function _checkEmergencyDeleveragerOrAnyone() internal view {
        require(
            msg.sender == emergencyDeleverager || _isSoftLiquidationEnabledForAnyone(boolSlot),
            OnlyEmergencyDeleveragerInvalidCaller(msg.sender)
        );
    }
}
