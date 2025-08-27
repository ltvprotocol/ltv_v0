// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {BorrowVaultModule} from "../../src/elements/BorrowVaultModule.sol";
import {console} from "forge-std/console.sol";

contract DeployBorrowVaultModule is BaseScript {
    function deploy() internal override {
        BorrowVaultModule borrowVaultModule = new BorrowVaultModule{salt: bytes32(0)}();
        console.log("BorrowVaultModule deployed at: ", address(borrowVaultModule));
    }

    function hashedCreationCode() internal pure override returns (bytes32) {
        return keccak256(type(BorrowVaultModule).creationCode);
    }
}
