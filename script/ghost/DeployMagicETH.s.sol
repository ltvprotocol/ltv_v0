// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {MagicETH} from "src/ghost/magic/MagicETH.sol";

contract DeployMagicETH is Script {
    function run() public {
        address proxyOwner = vm.envAddress("PROXY_OWNER");
        address magicEthOwner = vm.envAddress("MAGIC_ETH_OWNER");

        vm.startBroadcast();
        address magicEthProxy = Upgrades.deployTransparentProxy(
            "MagicETH.sol", proxyOwner, abi.encodeCall(MagicETH.initialize, (magicEthOwner))
        );
        vm.stopBroadcast();

        console.log("MagicETH deployed at: ", magicEthProxy);
    }
}
