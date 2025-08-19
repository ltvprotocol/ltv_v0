// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ISpookyOracle} from "src/ghost/spooky/ISpookyOracle.sol";
import {SpookyOracleConnector} from "src/ghost/connectors/SpookyOracleConnector.sol";

// SPOOKY_ORACLE=ORACLE_ADDRESS COLLATERAL_TOKEN=COLLATERAL_ADDRESS BORROW_TOKEN=BORROW_ADDRESS forge script --fork-url localhost:8545 script/DeployOracleConnector.s.sol:DeploySpookyOracleConnector --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
contract DeploySpookyOracleConnector is Script {
    function run() external {
        address spookyOracle = vm.envAddress("SPOOKY_ORACLE");

        vm.startBroadcast();
        SpookyOracleConnector connector = new SpookyOracleConnector(ISpookyOracle(spookyOracle));
        vm.stopBroadcast();

        console.log("Spooky oracle connector address: ", address(connector));
    }
}
