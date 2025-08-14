// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../utils/BaseScript.s.sol";
import "../../src/connectors/lending_connectors/VaultBalanceAsLendingConnector.sol";

contract DeployVaultBalanceAsLendingConnector is BaseScript {
    function deploy() internal override {
        address collateralToken = vm.envAddress("COLLATERAL_ASSET");
        address borrowToken = vm.envAddress("BORROW_ASSET");

        VaultBalanceAsLendingConnector vaultBalanceAsLendingConnector =
            new VaultBalanceAsLendingConnector{salt: bytes32(0)}(IERC20(collateralToken), IERC20(borrowToken));
        console.log("VaultBalanceAsLendingConnector deployed at: ", address(vaultBalanceAsLendingConnector));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        address collateralToken = vm.envAddress("COLLATERAL_ASSET");
        address borrowToken = vm.envAddress("BORROW_ASSET");

        return keccak256(
            abi.encodePacked(
                type(VaultBalanceAsLendingConnector).creationCode, abi.encode(collateralToken, borrowToken)
            )
        );
    }
}
