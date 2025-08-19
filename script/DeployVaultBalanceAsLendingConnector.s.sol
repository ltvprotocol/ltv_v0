// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {VaultBalanceAsLendingConnector} from "src/connectors/lending_connectors/VaultBalanceAsLendingConnector.sol";

contract DeployVaultBalanceAsLendingConnector is Script {
    function run() external {
        vm.startBroadcast();

        VaultBalanceAsLendingConnector vaultBalanceAsLendingConnector = new VaultBalanceAsLendingConnector();
        vm.stopBroadcast();

        console.log("VaultBalanceAsLendingConnector deployed at: ", address(vaultBalanceAsLendingConnector));
    }
}
