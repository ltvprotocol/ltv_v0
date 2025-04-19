// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../states/LTVState.sol';
import '../utils/UpgradeableOwnableWithGuardianAndGovernor.sol';

contract FunctionStopper is LTVState, UpgradeableOwnableWithGuardianAndGovernor {
    error FunctionStopped(bytes4 functionSignature);

    modifier isFunctionAllowed() {
        _checkFunctionAllowed();
        _;
    }

    function _checkFunctionAllowed() private view {
        require(!_isFunctionDisabled[msg.sig] || _msgSender() == owner() || _msgSender() == governor(), FunctionStopped(msg.sig));
    }
}
