// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {MorphoConnector} from "../../src/connectors/lending_connectors/MorphoConnector.sol";
import {console} from "forge-std/console.sol";

contract DeployMorphoLendingConnector is BaseScript {
    function deploy() internal override {
        MorphoConnector connector = new MorphoConnector{salt: bytes32(0)}();
        console.log("Morpho connector deployed at", address(connector));
    }

    function hashedCreationCode() internal pure override returns (bytes32) {
        return keccak256(type(MorphoConnector).creationCode);
    }
}
