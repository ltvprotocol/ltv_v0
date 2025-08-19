// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {VaultBalanceAsLendingConnector} from
    "../../src/connectors/lending_connectors/VaultBalanceAsLendingConnector.sol";
import {console} from "forge-std/console.sol";

contract DeployVaultBalanceAsLendingConnector is BaseScript {
    function deploy() internal override {
        VaultBalanceAsLendingConnector vaultBalanceAsLendingConnector =
            new VaultBalanceAsLendingConnector{salt: bytes32(0)}();
        console.log("VaultBalanceAsLendingConnector deployed at: ", address(vaultBalanceAsLendingConnector));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        return keccak256(abi.encodePacked(type(VaultBalanceAsLendingConnector).creationCode));
    }
}
