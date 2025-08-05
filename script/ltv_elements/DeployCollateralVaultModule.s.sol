// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../utils/BaseScript.s.sol";
import "../../src/elements/CollateralVaultModule.sol";

contract DeployCollateralVaultModule is BaseScript {
    function deploy() internal override {
        CollateralVaultModule collateralVaultModule = new CollateralVaultModule{salt: bytes32(0)}();
        console.log("CollateralVaultModule deployed at: ", address(collateralVaultModule));
    }

    function hashedCreationCode() internal pure override returns (bytes32) { 
        return keccak256(type(CollateralVaultModule).creationCode);
    }
} 