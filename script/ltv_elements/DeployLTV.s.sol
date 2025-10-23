// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {LTV} from "../../src/elements/LTV.sol";
import {console} from "forge-std/console.sol";

contract DeployLTV is BaseScript {
    function deploy() internal override {
        address modules = vm.envAddress("MODULES_PROVIDER");
        LTV ltv = new LTV{salt: bytes32(0)}(modules);
        console.log("LTV deployed at: ", address(ltv));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        return keccak256(abi.encodePacked(type(LTV).creationCode, abi.encode(vm.envAddress("MODULES_PROVIDER"))));
    }
}
