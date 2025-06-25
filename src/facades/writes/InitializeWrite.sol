// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./AdministrationWrite.sol";
import "../../interfaces/IModules.sol";
import "../../structs/state/StateInitData.sol";
import "src/interfaces/IModules.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../utils/RevertWithDataIfNeeded.sol";

abstract contract InitializeWrite is AdministrationWrite, RevertWithDataIfNeeded {
    function initialize(StateInitData memory initData, IModules modules) external initializer {
        _setModules(modules);
        (bool isSuccess, bytes memory data) =
            address(modules.initializeModule()).delegatecall(abi.encodeCall(IInitializeModule.initialize, (initData)));
        revertWithDataIfNeeded(isSuccess, data);
    }
}
