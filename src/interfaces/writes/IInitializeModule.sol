// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {StateInitData} from "../../structs/state/initialize/StateInitData.sol";

/**
 * @title IInitializeModule
 * @notice Interface defining initialize function for LTV protocol
 */
interface IInitializeModule {
    /**
     * @dev After modules are set, this function is called to initialize the LTV protocol
     */
    function initialize(StateInitData memory initData) external;
}
