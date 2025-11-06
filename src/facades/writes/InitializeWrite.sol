// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {StateInitData} from "../../structs/state/initialize/StateInitData.sol";
import {FacadeImplementationState} from "../../states/FacadeImplementationState.sol";
import {CommonWrite} from "CommonWrite.sol";
/**
 * @title InitializeWrite
 * @notice This contract contains initialize part of the LTV protocol.
 * To initialize LTV protocol with modules, we need to have modules initialization logic in
 * the facade contract. After modules initialization, remaining part of LTV protocol can be initialized
 * via initialize module.
 */

abstract contract InitializeWrite is CommonWrite, FacadeImplementationState {
    /**
     * @dev see ILTV.initialize
     */
    function initialize(StateInitData memory initData) external {
        _delegate(address(MODULES.initializeModule()), abi.encode(initData));
    }
}
