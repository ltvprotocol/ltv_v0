// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseScript.s.sol";
import "../../src/connectors/oracle_connectors/AaveV3OracleConnector.sol";

contract DeployAaveOracleConnector is BaseScript {
    function deploy() internal override {
        address collateralAsset = vm.envAddress("COLLATERAL_ASSET");
        address borrowAsset = vm.envAddress("BORROW_ASSET");

        AaveV3OracleConnector connector = new AaveV3OracleConnector{salt: bytes32(0)}(collateralAsset, borrowAsset);
        console.log("Aave connector deployed at", address(connector));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        address collateralAsset = vm.envAddress("COLLATERAL_ASSET");
        address borrowAsset = vm.envAddress("BORROW_ASSET");

        return keccak256(
            abi.encodePacked(type(AaveV3OracleConnector).creationCode, abi.encode(collateralAsset, borrowAsset))
        );
    }
}
