// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {MorphoOracleConnector} from "../../src/connectors/oracle_connectors/MorphoOracleConnector.sol";
import {IMorphoOracle} from "../../src/connectors/oracle_connectors/interfaces/IMorphoOracle.sol";
import {console} from "forge-std/console.sol";

contract DeployMorphoOracleConnector is BaseScript {
    function deploy() internal override {
        address oracle = vm.envAddress("ORACLE");

        MorphoOracleConnector connector = new MorphoOracleConnector{salt: bytes32(0)}(IMorphoOracle(oracle));
        console.log("Morpho connector deployed at", address(connector));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        address oracle = vm.envAddress("ORACLE");

        return keccak256(abi.encodePacked(type(MorphoOracleConnector).creationCode, abi.encode(oracle)));
    }
}
