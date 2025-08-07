// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseScript.s.sol";
import "../../src/connectors/oracle_connectors/AaveV3OracleConnector.sol";

contract DeployAaveOracleConnector is BaseScript {
    function deploy() internal override {
        address collateralAsset = vm.envAddress("COLLATERAL_ASSET");
        address borrowAsset = vm.envAddress("BORROW_ASSET");

        AaveV3OracleConnector connector =
            new AaveV3OracleConnector{salt: bytes32(0)}(collateralAsset, borrowAsset, getAaveV3Oracle());
        console.log("Aave connector deployed at", address(connector));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        address collateralAsset = vm.envAddress("COLLATERAL_ASSET");
        address borrowAsset = vm.envAddress("BORROW_ASSET");

        return keccak256(
            abi.encodePacked(
                type(AaveV3OracleConnector).creationCode, abi.encode(collateralAsset, borrowAsset, getAaveV3Oracle())
            )
        );
    }

    function getAaveV3Oracle() internal view returns (address) {
        if (block.chainid == 1) {
            return 0x54586bE62E3c3580375aE3723C145253060Ca0C2;
        } else if (block.chainid == 11155111) {
            return 0x2da88497588bf89281816106C7259e31AF45a663;
        } else {
            revert("Unsupported chain");
        }
    }
}
