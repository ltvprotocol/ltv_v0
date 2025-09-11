// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {InitializeModule} from "../../src/elements/modules/InitializeModule.sol";
import {console} from "forge-std/console.sol";

contract DeployInitializeModule is BaseScript {
    function deploy() internal override {
        InitializeModule initializeModule = new InitializeModule{salt: bytes32(0)}();
        console.log("InitializeModule deployed at: ", address(initializeModule));
    }

    function hashedCreationCode() internal pure override returns (bytes32) {
        return keccak256(type(InitializeModule).creationCode);
    }
}
