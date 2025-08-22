// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {AaveV3OracleConnector} from "../../src/connectors/oracle_connectors/AaveV3OracleConnector.sol";
import {console} from "forge-std/console.sol";

contract DeployAaveOracleConnector is BaseScript {
    function deploy() internal override {
        AaveV3OracleConnector connector = new AaveV3OracleConnector{salt: bytes32(0)}(getAaveV3Oracle());
        console.log("Aave connector deployed at", address(connector));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        return keccak256(abi.encodePacked(type(AaveV3OracleConnector).creationCode, abi.encode(getAaveV3Oracle())));
    }

    function getAaveV3Oracle() internal view returns (address) {
        if (block.chainid == 1) {
            return 0x54586bE62E3c3580375aE3723C145253060Ca0C2;
        } else if (block.chainid == 11155111) {
            return 0x2da88497588bf89281816106C7259e31AF45a663;
        } else {
            revert("Unsupported chain");
        }
    }
}
