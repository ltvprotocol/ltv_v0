// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {console} from "forge-std/console.sol";
import {ISpookyOracle} from "../../src/ghost/spooky/ISpookyOracle.sol";
import {SpookyOracleConnector} from "../../src/ghost/connectors/SpookyOracleConnector.sol";

// SPOOKY_ORACLE=ORACLE_ADDRESS COLLATERAL_TOKEN=COLLATERAL_ADDRESS BORROW_TOKEN=BORROW_ADDRESS forge script --fork-url localhost:8545 script/DeployOracleConnector.s.sol:DeploySpookyOracleConnector --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
contract DeploySpookyOracleConnector is BaseScript {
    function deploy() internal override {
        address spookyOracle = vm.envAddress("ORACLE");

        SpookyOracleConnector connector = new SpookyOracleConnector{salt: bytes32(0)}(ISpookyOracle(spookyOracle));

        console.log("Spooky oracle connector address: ", address(connector));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        address spookyOracle = vm.envAddress("ORACLE");

        return keccak256(abi.encodePacked(type(SpookyOracleConnector).creationCode, abi.encode(spookyOracle)));
    }
}
