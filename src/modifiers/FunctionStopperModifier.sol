// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";
import {LTVState} from "src/states/LTVState.sol";

/**
 * @title FunctionStopperModifier
 * @notice This contract contains modifiers for the function stopping functionality of the LTV protocol.
 * It checks if the function is allowed to be called.
 */
abstract contract FunctionStopperModifier is LTVState, OwnableUpgradeable, IAdministrationErrors {
    /**
     * @dev modifier to check if the function is allowed to be called
     */
    modifier isFunctionAllowed() {
        _checkFunctionAllowed();
        _;
    }

    /**
     * @dev checks if the function is allowed to be called
     */
    function _checkFunctionAllowed() private view {
        require(!_isFunctionDisabled[msg.sig], FunctionStopped(msg.sig));
    }
}
