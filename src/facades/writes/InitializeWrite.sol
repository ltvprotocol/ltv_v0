// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IModules} from "src/interfaces/IModules.sol";
import {IInitializeModule} from "src/interfaces/writes/IInitializeModule.sol";
import {StateInitData} from "src/structs/state/initialize/StateInitData.sol";
import {AdministrationWrite} from "src/facades/writes/AdministrationWrite.sol";
import {RevertWithDataIfNeeded} from "src/utils/RevertWithDataIfNeeded.sol";

/**
 * @title InitializeWrite
 * @notice This contract contains initialize part of the LTV protocol.
 * To initialize LTV protocol with modules, we need to have modules initialization logic in
 * the facade contract. After modules initialization, remaining part of LTV protocol can be initialized
 * via initialize module.
 */
abstract contract InitializeWrite is AdministrationWrite, RevertWithDataIfNeeded {
    function initialize(StateInitData memory initData, IModules modules) external initializer {
        _setModules(modules);
        (bool isSuccess, bytes memory data) =
            address(modules.initializeModule()).delegatecall(abi.encodeCall(IInitializeModule.initialize, (initData)));
        revertWithDataIfNeeded(isSuccess, data);
    }
}
