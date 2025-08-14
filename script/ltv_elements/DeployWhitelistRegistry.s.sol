// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../utils/BaseScript.s.sol";
import "../../src/elements/WhitelistRegistry.sol";

contract DeployWhitelistRegistry is BaseScript {
    function deploy() internal override {
        address owner = vm.envAddress("WHITELIST_OWNER");

        WhitelistRegistry whitelistRegistry = new WhitelistRegistry{salt: bytes32(0)}(owner);
        console.log("WhitelistRegistry deployed at: ", address(whitelistRegistry));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        address owner = vm.envAddress("WHITELIST_OWNER");
        return keccak256(abi.encodePacked(type(WhitelistRegistry).creationCode, abi.encode(owner)));
    }
}
