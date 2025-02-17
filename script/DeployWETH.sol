

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {WETH} from "src/dummy/weth/WETH.sol";

contract DeployWETH is Script {
    function setUp() public {}

    function run() public {

        address proxyOwner = vm.envAddress("PROXY_OWNER");
        address wethOwner = vm.envAddress("WETH_OWNER");

        vm.startBroadcast(); // Start broadcasting transactions

        WETH weth = new WETH();

        address proxyWETH = Upgrades.deployTransparentProxy(
            "WETH.sol",
            address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266),
            abi.encodeCall(weth.initialize, (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266))
        );

        console.log("WETH at:       ", address(weth));
        console.log("Proxy WETH at: ", proxyWETH);

        vm.stopBroadcast();
    }
}
