// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import 'forge-std/Script.sol';
import '../src/ghost/spooky/ISpookyOracle.sol';
import '../src/ghost/connectors/SpookyOracleConnector.sol';

// SPOOKY_ORACLE=ORACLE_ADDRESS COLLATERAL_TOKEN=COLLATERAL_ADDRESS BORROW_TOKEN=BORROW_ADDRESS forge script --fork-url localhost:8545 script/DeployOracleConnector.s.sol:DeploySpookyOracleConnector --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
contract DeploySpookyOracleConnector is Script {
    function run() external {
        address spookyOracle = vm.envAddress('SPOOKY_ORACLE');
        address collateralToken = vm.envAddress('COLLATERAL_TOKEN');
        address borrowToken = vm.envAddress('BORROW_TOKEN');

        vm.startBroadcast();
        SpookyOracleConnector connector = new SpookyOracleConnector(
            IERC20(collateralToken),
            IERC20(borrowToken),
            ISpookyOracle(spookyOracle)
        );
        vm.stopBroadcast();

        console.log('Spooky oracle connector address: ', address(connector));
    }
}