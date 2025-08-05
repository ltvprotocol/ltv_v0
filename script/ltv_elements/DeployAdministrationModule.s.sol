// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../utils/BaseScript.s.sol";
import "../../src/elements/AdministrationModule.sol";

contract DeployAdministrationModule is BaseScript {
    function deploy() internal override {
        AdministrationModule administrationModule = new AdministrationModule{salt: bytes32(0)}();
        console.log("AdministrationModule deployed at: ", address(administrationModule));
    }

    function hashedCreationCode() internal pure override returns (bytes32) { 
        return keccak256(type(AdministrationModule).creationCode);
    }
} 