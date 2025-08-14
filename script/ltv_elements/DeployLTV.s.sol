// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../utils/BaseScript.s.sol";
import "../../src/elements/LTV.sol";

contract DeployLTV is BaseScript {
    function deploy() internal override {
        LTV ltv = new LTV{salt: bytes32(0)}();
        console.log("LTV deployed at: ", address(ltv));
    }

    function hashedCreationCode() internal pure override returns (bytes32) {
        return keccak256(type(LTV).creationCode);
    }
}
