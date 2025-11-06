// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {ILTV} from "../src/interfaces/ILTV.sol";
import {
    ProxyAdmin, ITransparentUpgradeableProxy
} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {UpgradeableBeacon} from "openzeppelin-contracts/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {GetConnectorData} from "./utils/GetConnectorData.s.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Utils} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol";

contract UpgradeLtv is Script, GetConnectorData {
    function run() public {
        _upgradeImplementationIfNeeded();
        _upgradeOracleConnectorIfNeeded();
        _upgradeLendingConnectorIfNeeded();
        _upgradeSlippageConnectorIfNeeded();
        _upgradeVaultBalanceAsLendingConnectorIfNeeded();
    }

    function _upgradeImplementationIfNeeded() internal {
        address proxyAdmin = vm.envOr("PROXY_ADMIN", address(0));
        address beacon = vm.envOr("BEACON", address(0));
        address ltv = vm.envAddress("LTV_BEACON_PROXY");

        require((proxyAdmin == address(0)) != (beacon == address(0)), "Only one of PROXY_ADMIN or BEACON must be set");

        address newImplementation = vm.envAddress("LTV");
        if (proxyAdmin == address(0)) {
            address oldImplementation = UpgradeableBeacon(beacon).implementation();
            if (oldImplementation != newImplementation) {
                vm.startBroadcast();
                UpgradeableBeacon(beacon).upgradeTo(newImplementation);
                vm.stopBroadcast();
                console.log("LTV upgraded to ", newImplementation);
            } else {
                console.log("LTV is already up to date");
            }
        } else {
            address oldImplementation =
                address(uint160(uint256(vm.load(address(ltv), ERC1967Utils.IMPLEMENTATION_SLOT))));
            if (oldImplementation != newImplementation) {
                vm.startBroadcast();
                ProxyAdmin(proxyAdmin).upgradeAndCall(ITransparentUpgradeableProxy(ltv), newImplementation, "");
                vm.stopBroadcast();
                console.log("LTV upgraded to ", newImplementation);
            } else {
                console.log("LTV is already up to date");
            }
        }
    }

    function _upgradeOracleConnectorIfNeeded() internal {
        address oracleConnector = vm.envAddress("ORACLE_CONNECTOR");
        address ltv = vm.envAddress("LTV_BEACON_PROXY");
        address oldOracleConnector = ILTV(ltv).oracleConnector();
        if (oldOracleConnector != oracleConnector) {
            bytes memory oracleConnectorData = getOracleConnectorInitData();
            vm.startBroadcast();
            ILTV(ltv).setOracleConnector(oracleConnector, oracleConnectorData);
            vm.stopBroadcast();
            console.log("Oracle connector upgraded to ", oracleConnector);
        }
    }

    function _upgradeLendingConnectorIfNeeded() internal {
        address lendingConnector = vm.envAddress("LENDING_CONNECTOR");
        address ltv = vm.envAddress("LTV_BEACON_PROXY");
        address oldLendingConnector = ILTV(ltv).lendingConnector();
        if (oldLendingConnector != lendingConnector) {
            bytes memory lendingConnectorData = getLendingConnectorInitData();
            vm.startBroadcast();
            ILTV(ltv).setLendingConnector(lendingConnector, lendingConnectorData);
            vm.stopBroadcast();
            console.log("Lending connector upgraded to ", lendingConnector);
        }
    }

    function _upgradeSlippageConnectorIfNeeded() internal {
        address slippageConnector = vm.envAddress("SLIPPAGE_CONNECTOR");
        address ltv = vm.envAddress("LTV_BEACON_PROXY");
        address oldSlippageConnector = ILTV(ltv).slippageConnector();
        if (oldSlippageConnector != slippageConnector) {
            bytes memory slippageConnectorData = getSlippageConnectorInitData();
            vm.startBroadcast();
            ILTV(ltv).setSlippageConnector(slippageConnector, slippageConnectorData);
            vm.stopBroadcast();
            console.log("Slippage connector upgraded to ", slippageConnector);
        }
    }

    function _upgradeVaultBalanceAsLendingConnectorIfNeeded() internal {
        address vaultBalanceAsLendingConnector = vm.envAddress("VAULT_BALANCE_AS_LENDING_CONNECTOR");
        address ltv = vm.envAddress("LTV_BEACON_PROXY");
        address oldVaultBalanceAsLendingConnector = ILTV(ltv).vaultBalanceAsLendingConnector();
        if (oldVaultBalanceAsLendingConnector != vaultBalanceAsLendingConnector) {
            bytes memory vaultBalanceAsLendingConnectorData = getVaultBalanceAsLendingConnectorInitData();
            vm.startBroadcast();
            ILTV(ltv).setVaultBalanceAsLendingConnector(
                vaultBalanceAsLendingConnector, vaultBalanceAsLendingConnectorData
            );
            vm.stopBroadcast();
            console.log("Vault balance as lending connector upgraded to ", vaultBalanceAsLendingConnector);
        }
    }
}
