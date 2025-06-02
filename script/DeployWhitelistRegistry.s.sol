// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "forge-std/Script.sol";
import "../src/elements/WhitelistRegistry.sol";

contract DeployWhitelistRegistry is Script {
    function run() external {
        vm.startBroadcast();
        address owner = vm.envAddress("WHITELIST_OWNER");

        // Deploy the WhitelistRegistry contract
        WhitelistRegistry whitelistRegistry = new WhitelistRegistry(owner);

        vm.stopBroadcast();

        console.log("WhitelistRegistry deployed at: ", address(whitelistRegistry));
    }
}
