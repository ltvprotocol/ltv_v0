// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {MorphoOracleConnector} from "../../src/connectors/oracle_connectors/MorphoOracleConnector.sol";
import {console} from "forge-std/console.sol";
import {GetMorphoPool} from "./GetMorphoPool.s.sol";

contract DeployMorphoOracleConnector is BaseScript {
    function deploy() internal override {
        address morpho = GetMorphoPool.getMorphoPool();
        MorphoOracleConnector connector = new MorphoOracleConnector{salt: bytes32(0)}(morpho);
        console.log("Morpho oracle connector deployed at", address(connector));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        address morpho = GetMorphoPool.getMorphoPool();

        return keccak256(abi.encodePacked(type(MorphoOracleConnector).creationCode, abi.encode(morpho)));
    }
}
