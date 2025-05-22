// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import 'forge-std/Script.sol';
import '../src/connectors/lending_connectors/VaultBalanceAsLendingConnector.sol';

contract DeployVaultBalanceAsLendingConnector is Script {
    function run() external {
        address collateralToken = vm.envAddress('COLLATERAL_TOKEN');
        address borrowToken = vm.envAddress('BORROW_TOKEN');

        vm.startBroadcast();

        VaultBalanceAsLendingConnector vaultBalanceAsLendingConnector = new VaultBalanceAsLendingConnector(
            IERC20(collateralToken),
            IERC20(borrowToken)
        );

        vm.stopBroadcast();

        console.log("VaultBalanceAsLendingConnector deployed at: ", address(vaultBalanceAsLendingConnector));
    }
}