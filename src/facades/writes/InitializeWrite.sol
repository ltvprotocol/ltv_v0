// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IInitializeModule} from "src/interfaces/reads/IInitializeModule.sol";
import {IModules} from "src/interfaces/IModules.sol";
import {StateInitData} from "src/structs/state/StateInitData.sol";
import {AdministrationWrite} from "src/facades/writes/AdministrationWrite.sol";
import {RevertWithDataIfNeeded} from "src/utils/RevertWithDataIfNeeded.sol";

abstract contract InitializeWrite is AdministrationWrite, RevertWithDataIfNeeded {
    function initialize(StateInitData memory initData, IModules modules) external initializer {
        _setModules(modules);
        (bool isSuccess, bytes memory data) =
            address(modules.initializeModule()).delegatecall(abi.encodeCall(IInitializeModule.initialize, (initData)));
        revertWithDataIfNeeded(isSuccess, data);
    }
}
