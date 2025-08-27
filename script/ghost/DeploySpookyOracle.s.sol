// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {SpookyOracle} from "src/ghost/spooky/SpookyOracle.sol";

contract DeploySpookyOracle is Script {
    function run() public {
        address proxyOwner = vm.envAddress("PROXY_OWNER");
        address oracleOwner = vm.envAddress("ORACLE_OWNER");
        address borrowToken = vm.envAddress("BORROW_TOKEN");
        address collateralToken = vm.envAddress("COLLATERAL_TOKEN");

        vm.startBroadcast();
        address spookyOracleProxy = Upgrades.deployTransparentProxy(
            "SpookyOracle.sol", proxyOwner, abi.encodeCall(SpookyOracle.initialize, msg.sender)
        );

        SpookyOracle(spookyOracleProxy).setAssetPrice(borrowToken, 10 ** 18);
        SpookyOracle(spookyOracleProxy).setAssetPrice(collateralToken, 10 ** 18);

        SpookyOracle(spookyOracleProxy).transferOwnership(oracleOwner);
        vm.stopBroadcast();
        console.log("Spooky oracle deployed at: ", spookyOracleProxy);
    }
}
