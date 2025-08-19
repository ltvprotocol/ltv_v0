// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseScript.s.sol";
import "../../src/connectors/oracle_connectors/AaveV3OracleConnector.sol";

contract DeployAaveOracleConnector is BaseScript {
    function deploy() internal override {
        AaveV3OracleConnector connector = new AaveV3OracleConnector{salt: bytes32(0)}();
        console.log("Aave connector deployed at", address(connector));
    }

    function hashedCreationCode() internal pure override returns (bytes32) {
        return keccak256(type(AaveV3OracleConnector).creationCode);
    }
}
