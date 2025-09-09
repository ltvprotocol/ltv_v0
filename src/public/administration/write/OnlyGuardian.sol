// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AdministrationModifiers} from "../../../modifiers/AdministrationModifiers.sol";
import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {AdmistrationSetters} from "../../../state_transition/AdmistrationSetters.sol";

abstract contract OnlyGuardian is AdmistrationSetters, ReentrancyGuardUpgradeable, AdministrationModifiers {
    function allowDisableFunctions(bytes4[] memory signatures, bool isDisabled) external onlyGuardian nonReentrant {
        _allowDisableFunctions(signatures, isDisabled);
    }

    function setIsDepositDisabled(bool value) external onlyGuardian nonReentrant {
        _setIsDepositDisabled(value);
    }

    function setIsWithdrawDisabled(bool value) external onlyGuardian nonReentrant {
        _setIsWithdrawDisabled(value);
    }
}
