// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {LowLevelRebalanceModule} from "../../src/elements/modules/LowLevelRebalanceModule.sol";
import {console} from "forge-std/console.sol";

contract DeployLowLevelRebalanceModule is BaseScript {
    function deploy() internal override {
        LowLevelRebalanceModule lowLevelRebalanceModule = new LowLevelRebalanceModule{salt: bytes32(0)}();
        console.log("LowLevelRebalanceModule deployed at: ", address(lowLevelRebalanceModule));
    }

    function hashedCreationCode() internal pure override returns (bytes32) {
        return keccak256(type(LowLevelRebalanceModule).creationCode);
    }
}
