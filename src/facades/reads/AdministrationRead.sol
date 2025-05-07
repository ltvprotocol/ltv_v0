// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/LTVState.sol";

abstract contract AdministrationRead is LTVState {
    function owner() external view returns (address) {
        return modules.administration().owner();
    }

    function guardian() external view returns (address) {
        return modules.administration().guardian();
    }

    function deleverageWithdrawer() external view returns (address) {
        return modules.administration().deleverageWithdrawer();
    }

    function governor() external view returns (address) {
        return modules.administration().governor();
    }
}
