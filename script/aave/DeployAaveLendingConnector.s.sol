// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {AaveV3Connector} from "../../src/connectors/lending_connectors/AaveV3Connector.sol";
import {console} from "forge-std/console.sol";

contract DeployAaveLendingConnector is BaseScript {
    function deploy() internal override {
        AaveV3Connector connector = new AaveV3Connector{salt: bytes32(0)}(getAaveV3Pool());
        console.log("Aave connector deployed at", address(connector));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        return keccak256(abi.encodePacked(type(AaveV3Connector).creationCode, abi.encode(getAaveV3Pool())));
    }

    function getAaveV3Pool() internal view returns (address) {
        if (block.chainid == 1) {
            return 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
        } else if (block.chainid == 11155111) {
            return 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
        } else {
            revert("Unsupported chain");
        }
    }
}
