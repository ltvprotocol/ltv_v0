// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../states/LTVState.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import 'src/errors/IAdministrationErrors.sol';

abstract contract FunctionStopperModifier is LTVState, OwnableUpgradeable, IAdministrationErrors {
    modifier isFunctionAllowed() {
        _checkFunctionAllowed();
        _;
    }

    function _checkFunctionAllowed() private view {
        require(!_isFunctionDisabled[msg.sig] || msg.sender == owner() || msg.sender == governor, FunctionStopped(msg.sig));
    }
}
