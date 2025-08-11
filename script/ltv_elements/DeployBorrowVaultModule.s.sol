// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../utils/BaseScript.s.sol";
import "../../src/elements/BorrowVaultModule.sol";

contract DeployBorrowVaultModule is BaseScript {
    function deploy() internal override {
        BorrowVaultModule borrowVaultModule = new BorrowVaultModule{salt: bytes32(0)}();
        console.log("BorrowVaultModule deployed at: ", address(borrowVaultModule));
    }

    function hashedCreationCode() internal pure override returns (bytes32) {
        return keccak256(type(BorrowVaultModule).creationCode);
    }
}
