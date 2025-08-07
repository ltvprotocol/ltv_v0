// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseScript.s.sol";
import "../../src/connectors/lending_connectors/AaveV3Connector.sol";

contract DeployAaveLendingConnector is BaseScript {
    function deploy() internal override {
        AaveV3Connector connector = new AaveV3Connector{salt: bytes32(0)}();
        console.log("Aave connector deployed at", address(connector));
    }

    function hashedCreationCode() internal pure override returns (bytes32) {
        return keccak256(type(AaveV3Connector).creationCode);
    }
}
