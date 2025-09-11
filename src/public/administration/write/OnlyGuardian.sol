// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AdministrationModifiers} from "../../../modifiers/AdministrationModifiers.sol";
import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {AdministrationSetters} from "../../../state_transition/AdministrationSetters.sol";

/**
 * @title OnlyGuardian
 * @notice This contract contains only guardian public function implementation.
 */
abstract contract OnlyGuardian is AdministrationSetters, ReentrancyGuardUpgradeable, AdministrationModifiers {
    /**
     * @dev see ILTV.allowDisableFunctions
     */
    function allowDisableFunctions(bytes4[] memory signatures, bool isDisabled) external onlyGuardian nonReentrant {
        _allowDisableFunctions(signatures, isDisabled);
    }

    /**
     * @dev see ILTV.setIsDepositDisabled
     */
    function setIsDepositDisabled(bool value) external onlyGuardian nonReentrant {
        _setIsDepositDisabled(value);
    }

    /**
     * @dev see ILTV.setIsWithdrawDisabled
     */
    function setIsWithdrawDisabled(bool value) external onlyGuardian nonReentrant {
        _setIsWithdrawDisabled(value);
    }
}
