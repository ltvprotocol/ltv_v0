// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {WhitelistRegistry} from "../../src/elements/WhitelistRegistry.sol";
import {console} from "forge-std/console.sol";

contract DeployWhitelistRegistry is BaseScript {
    function deploy() internal override {
        address owner = vm.envAddress("WHITELIST_OWNER");
        address whitelistSigner = vm.envAddress("WHITELIST_SIGNER");

        WhitelistRegistry whitelistRegistry = new WhitelistRegistry{salt: bytes32(0)}(owner, whitelistSigner);
        console.log("WhitelistRegistry deployed at: ", address(whitelistRegistry));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        address owner = vm.envAddress("WHITELIST_OWNER");
        return keccak256(abi.encodePacked(type(WhitelistRegistry).creationCode, abi.encode(owner)));
    }
}
