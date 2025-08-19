// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../utils/BaseScript.s.sol";
import "../../src/connectors/slippage_providers/ConstantSlippageProvider.sol";

contract DeployConstantSlippageConnector is BaseScript {
    function deploy() internal override {
        ConstantSlippageProvider slippageProvider = new ConstantSlippageProvider{salt: bytes32(0)}();

        console.log("ConstantSlippageProvider deployed at: ", address(slippageProvider));
    }

    function hashedCreationCode() internal pure override returns (bytes32) {
        return keccak256(type(ConstantSlippageProvider).creationCode);
    }
}
