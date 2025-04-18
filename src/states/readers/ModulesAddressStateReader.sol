// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../LTVState.sol";

abstract contract ModulesAddressStateReader is LTVState {

    function getModules() internal view returns (IModules) {
        return modules;
    }
}
