// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "forge-std/Script.sol";
import "openzeppelin-foundry-upgrades/Upgrades.sol";
import "../../src/ghost/magic/MagicETH.sol";

contract DeployMagicETH is Script {
    function run() public {
        address proxyOwner = vm.envAddress("PROXY_OWNER");
        address magicETHOwner = vm.envAddress("MAGIC_ETH_OWNER");

        vm.startBroadcast();
        address magicETHProxy = Upgrades.deployTransparentProxy(
            "MagicETH.sol", proxyOwner, abi.encodeCall(MagicETH.initialize, (magicETHOwner))
        );
        vm.stopBroadcast();

        console.log("MagicETH deployed at: ", magicETHProxy);
    }
}
