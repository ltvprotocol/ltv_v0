// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/states/LTVState.sol';
import 'src/errors/Administration.sol';
import 'src/utils/UpgradeableOwnableWithGuardianAndGovernor.sol';
import 'src/events/Administration.sol';

contract SetTargetLTV is LTVState, UpgradeableOwnableWithGuardianAndGovernor, AdministrationErrors, AdministrationEvents {

    function setTargetLTV(uint128 value) external onlyGovernor {
        require(value <= maxSafeLTV && value >= minProfitLTV, InvalidLTVSet(value, maxSafeLTV, minProfitLTV));
        uint128 oldValue = targetLTV;
        targetLTV = value;
        emit TargetLTVChanged(oldValue, targetLTV);
    }

}
