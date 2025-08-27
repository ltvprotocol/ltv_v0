// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {MorphoConnector} from "../../src/connectors/lending_connectors/MorphoConnector.sol";
import {console} from "forge-std/console.sol";

contract DeployMorphoLendingConnector is BaseScript {
    function deploy() internal override {
        MorphoConnector connector = new MorphoConnector{salt: bytes32(0)}(getMorphoPool());
        console.log("Morpho connector deployed at", address(connector));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        return keccak256(abi.encodePacked(type(MorphoConnector).creationCode, abi.encode(getMorphoPool())));
    }

    function getMorphoPool() internal view returns (address) {
        if (block.chainid == 1) {
            return 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
        } else if (block.chainid == 11155111) {
            return 0xd011EE229E7459ba1ddd22631eF7bF528d424A14;
        } else {
            revert("Unsupported chain");
        }
    }
}
