// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

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
