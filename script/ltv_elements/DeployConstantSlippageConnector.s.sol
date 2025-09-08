// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {ConstantSlippageConnector} from "../../src/connectors/slippage_connectors/ConstantSlippageConnector.sol";
import {console} from "forge-std/console.sol";

contract DeployConstantSlippageConnector is BaseScript {
    function deploy() internal override {
        ConstantSlippageConnector slippageConnector = new ConstantSlippageConnector{salt: bytes32(0)}();

        console.log("ConstantSlippageConnector deployed at: ", address(slippageConnector));
    }

    function hashedCreationCode() internal pure override returns (bytes32) {
        return keccak256(type(ConstantSlippageConnector).creationCode);
    }
}
