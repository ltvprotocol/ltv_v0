// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/Script.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {WETH} from "../../src/dummy/weth/WETH.sol";

contract DeployWETH is Script {
    function setUp() public {}

    function run() public {
        address proxyOwner = vm.envAddress("PROXY_OWNER");
        address wethOwner = vm.envAddress("WETH_OWNER");

        vm.startBroadcast(); // Start broadcasting transactions

        //WETH weth = new WETH();

        address proxyWETH =
            Upgrades.deployTransparentProxy("WETH.sol", proxyOwner, abi.encodeCall(WETH.initialize, wethOwner));

        console.log("Proxy WETH at: ", proxyWETH);

        vm.stopBroadcast();
    }
}
