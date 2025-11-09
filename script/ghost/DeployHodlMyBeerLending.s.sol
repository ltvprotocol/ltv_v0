// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {HodlMyBeerLending} from "../../src/ghost/hodlmybeer/HodlMyBeerLending.sol";

contract DeployHodlMyBeerLending is Script {
    function run() public {
        address proxyOwner = vm.envAddress("PROXY_OWNER");
        address spookyOracle = vm.envAddress("SPOOKY_ORACLE");
        address borrowToken = vm.envAddress("BORROW_TOKEN");
        address collateralToken = vm.envAddress("COLLATERAL_TOKEN");

        vm.startBroadcast();
        address hodlMyBeerLendingProxy = Upgrades.deployTransparentProxy(
            "HodlMyBeerLending.sol",
            proxyOwner,
            abi.encodeCall(HodlMyBeerLending.initialize, (borrowToken, collateralToken, address(spookyOracle)))
        );
        vm.stopBroadcast();

        console.log("HodlMyBeerLending deployed at: ", hodlMyBeerLendingProxy);
    }
}
