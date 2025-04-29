// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/elements/LTV.sol';

contract LTVWithModules is LTV {
    function setModules(IModules _modules) public {
        modules = _modules;
    }
}
