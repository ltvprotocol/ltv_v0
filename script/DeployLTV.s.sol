// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/Script.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {MagicETH} from "src/ghost/magic/MagicETH.sol";

import "src/ghost/connectors/HodlLendingConnector.sol";
import "src/ghost/connectors/SpookyOracleConnector.sol";
import "src/interfaces/ISlippageProvider.sol";

import {WETH} from "../src/dummy/weth/WETH.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

// contract DeployImpl is Script {
//     function run() external {
//         vm.startBroadcast();
//         address ltv = address(new LTV());
//         vm.stopBroadcast();
//         console.log('impl deployed at: ', ltv);
//     }
// }

contract DeployBeacon is Script {
    function run() external {
        address ltvImpl = vm.envAddress("LTV_IMPL");
        address proxyOwner = vm.envAddress("PROXY_OWNER");
        vm.startBroadcast();
        address ltv = address(new UpgradeableBeacon(ltvImpl, proxyOwner));
        vm.stopBroadcast();
        console.log("beacon deployed at: ", ltv);
    }
}
