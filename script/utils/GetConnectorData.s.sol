// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";

contract GetConnectorData is Script {
    function getLendingConnectorInitData() internal view returns (bytes memory) {
        if (_isAaveConnector()) {
            return abi.encode(vm.envUint("EMODE"));
        } else if (_isMorphoConnector()) {
            address oracle = vm.envAddress("ORACLE");
            address irm = vm.envAddress("IRM");
            uint256 lltv = vm.envUint("LLTV");
            address borrowToken = vm.envAddress("BORROW_ASSET");
            address collateralToken = vm.envAddress("COLLATERAL_ASSET");
            bytes32 marketId = keccak256(abi.encode(borrowToken, collateralToken, oracle, irm, lltv));
            return abi.encode(oracle, irm, lltv, marketId);
        } else if (_isGhostConnector()) {
            return "";
        } else {
            revert("Unknown lending connector");
        }
    }

    function getOracleConnectorInitData() internal view returns (bytes memory) {
        if (_isAaveConnector()) {
            return "";
        } else if (_isMorphoConnector()) {
            address oracle = vm.envAddress("ORACLE");
            address irm = vm.envAddress("IRM");
            uint256 lltv = vm.envUint("LLTV");
            address borrowToken = vm.envAddress("BORROW_ASSET");
            address collateralToken = vm.envAddress("COLLATERAL_ASSET");
            bytes32 marketId = keccak256(abi.encode(borrowToken, collateralToken, oracle, irm, lltv));
            return abi.encode(oracle, marketId);
        } else if (_isGhostConnector()) {
            return "";
        } else {
            revert("Unknown oracle connector");
        }
    }

    function getVaultBalanceAsLendingConnectorInitData() internal pure returns (bytes memory) {
        return "";
    }

    function getSlippageConnectorInitData() internal view returns (bytes memory) {
        uint256 collateralSlippage = vm.envUint("COLLATERAL_SLIPPAGE");
        uint256 borrowSlippage = vm.envUint("BORROW_SLIPPAGE");
        return abi.encode(collateralSlippage, borrowSlippage);
    }

    function _isAaveConnector() internal view returns (bool) {
        string memory lendingConnectorName = vm.envString("LENDING_CONNECTOR_NAME");
        return keccak256(abi.encodePacked(lendingConnectorName)) == keccak256(abi.encodePacked("AaveV3"));
    }

    function _isMorphoConnector() internal view returns (bool) {
        string memory lendingConnectorName = vm.envString("LENDING_CONNECTOR_NAME");
        return keccak256(abi.encodePacked(lendingConnectorName)) == keccak256(abi.encodePacked("Morpho"));
    }

    function _isGhostConnector() internal view returns (bool) {
        string memory lendingConnectorName = vm.envString("LENDING_CONNECTOR_NAME");
        return keccak256(abi.encodePacked(lendingConnectorName)) == keccak256(abi.encodePacked("Ghost"));
    }
}
