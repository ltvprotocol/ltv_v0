// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/Script.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {MagicETH} from "src/ghost/magic/MagicETH.sol";

import "src/ghost/connectors/HodlLendingConnector.sol";
import "src/ghost/connectors/SpookyOracleConnector.sol";
import "src/interfaces/ISlippageProvider.sol";

import {WETH} from "../src/dummy/weth/WETH.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

// contract DeployImpl is Script {
//     function run() external {
//         vm.startBroadcast();
//         address ltv = address(new LTV());
//         vm.stopBroadcast();
//         console.log('impl deployed at: ', ltv);
//     }
// }

contract DeployBeacon is Script {
    function run() external {
        address ltvImpl = vm.envAddress("LTV_IMPL");
        address proxyOwner = vm.envAddress("PROXY_OWNER");
        vm.startBroadcast();
        address ltv = address(new UpgradeableBeacon(ltvImpl, proxyOwner));
        vm.stopBroadcast();
        console.log("beacon deployed at: ", ltv);
    }
}

// contract DeployGhostLTV is Script {
//     function run() public {
//         address ltvOwner = vm.envAddress('LTV_OWNER');
//         address ltvGuardian = vm.envAddress('LTV_GUARDIAN');
//         address ltvGovernor = vm.envAddress('LTV_GOVERNOR');
//         address ltvEmergencyDeleverager = vm.envAddress('LTV_EMERGENCY_DELEVERAGER');
//         address feeCollector = vm.envAddress('FEE_COLLECTOR');
//         address beacon = vm.envAddress('BEACON');
//         address collateralToken = vm.envAddress('COLLATERAL_TOKEN');
//         address borrowToken = vm.envAddress('BORROW_TOKEN');
//         address hodlLendingConnector = vm.envAddress('HODL_LENDING_CONNECTOR');
//         address spookyOracleConnector = vm.envAddress('SPOOKY_ORACLE_CONNECTOR');
//         address slippageProvider = vm.envAddress('SLIPPAGE_PROVIDER');
//         address vaultBalanceAsLendingConnector = vm.envAddress('VAULT_BALANCE_AS_LENDING_CONNECTOR');

//         State.StateInitData memory initData = State.StateInitData({
//             collateralToken: collateralToken,
//             borrowToken: borrowToken,
//             feeCollector: feeCollector,
//             maxSafeLTV: 9 * 10 ** 17,
//             minProfitLTV: 5 * 10 ** 17,
//             targetLTV: 75 * 10 ** 16,
//             lendingConnector: ILendingConnector(hodlLendingConnector),
//             oracleConnector: IOracleConnector(spookyOracleConnector),
//             maxGrowthFee: 10 ** 18 / 5,
//             maxTotalAssetsInUnderlying: type(uint128).max,
//             slippageProvider: ISlippageProvider(slippageProvider),
//             maxDeleverageFee: 2 * 10 ** 16,
//             vaultBalanceAsLendingConnector: ILendingConnector(vaultBalanceAsLendingConnector)
//         });

//         vm.startBroadcast(); // Start broadcasting transactions

//         address ltv = address(
//             new BeaconProxy(
//                 beacon,
//                 abi.encodeCall(LTV.initialize, (initData, ltvOwner, ltvGuardian, ltvGovernor, ltvEmergencyDeleverager, 'Ghost Magic ETH', 'GME'))
//             )
//         );
//         vm.stopBroadcast();
//         console.log('ltv at: ', ltv);
//     }
// }
