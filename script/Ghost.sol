

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {MagicETH} from "src/ghost/magic/MagicETH.sol";

import {HodlMyBeerLending} from "src/ghost/hodlmybeer/HodlMyBeerLending.sol";

import {SpookyOracle} from "src/ghost/spooky/SpookyOracle.sol";

import "../src/ltv_lendings/GhostLTV.sol";

import '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract DeployScript is Script {
    function setUp() public {}

    function run() public {

        // TODO: deploy LTV also

        address proxyOwner = vm.envAddress("PROXY_OWNER");
        address magicETHOwner = vm.envAddress("MAGIC_ETH_OWNER");
        address oracleOwner = vm.envAddress("ORACLE_OWNER");
        address weth = vm.envAddress("WETH");
        address ltvOwner = vm.envAddress("LTV_OWNER");
        address feeCollector = vm.envAddress("FEE_COLLECTOR");

        console.log("proxyOwner: ", proxyOwner);
        console.log("magicETHOwner: ", magicETHOwner);
        console.log("oracleOwner: ", oracleOwner);
        console.log("weth: ", weth);

        vm.startBroadcast(); // Start broadcasting transactions

        address magicETHProxy = Upgrades.deployTransparentProxy(
            "MagicETH.sol",
            proxyOwner,
            abi.encodeCall(MagicETH.initialize, (magicETHOwner))
        );

        // ------------------------------------------------

        address spookyOracleProxy = Upgrades.deployTransparentProxy(
            "SpookyOracle.sol",
            proxyOwner,
            abi.encodeCall(SpookyOracle.initialize, oracleOwner)
        );

        // ------------------------------------------------

        // TODO: add link to WETH

        address hodlMyBeerLendingProxy = Upgrades.deployTransparentProxy(
            "HodlMyBeerLending.sol",
            proxyOwner,
            abi.encodeCall(HodlMyBeerLending.initialize, (weth, address(magicETHProxy), address(spookyOracleProxy)))
        );

        Options memory options;
        options.unsafeAllow = 'external-library-linking';

        address impl = address(new GhostLTV());

        address ltv = address(new TransparentUpgradeableProxy(impl, proxyOwner, abi.encodeCall(GhostLTV.initialize, (ltvOwner, IHodlMyBeerLending(hodlMyBeerLendingProxy), ISpookyOracle(spookyOracleProxy), magicETHProxy, weth, feeCollector))));

        // ------------------------------------------------

        console.log("proxyMagicETH at:         ", magicETHProxy);
        console.log("hodlMyBeerLendingProxy at:", hodlMyBeerLendingProxy);
        console.log("spookyOracleProxy at:     ", spookyOracleProxy);
        console.log("ltv at:                   ", ltv);

        vm.stopBroadcast();
    }
}