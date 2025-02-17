

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {MagicETH} from "src/ghost/magic/MagicETH.sol";

import {HodlMyBeerLending} from "src/ghost/hodlmybeer/HodlMyBeerLending.sol";

import {SpookyOracle} from "src/ghost/spooky/SpookyOracle.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {

        // TODO: deploy LTV also

        // TODO: get contracts owner as parameter
        // TODO: get magicETH owner as parameter
        // TODO: oracle owner as parameter

        vm.startBroadcast(); // Start broadcasting transactions

        address magicETHProxy = Upgrades.deployTransparentProxy(
            "MagicETH.sol",
            address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266),
            abi.encodeCall(MagicETH.initialize, (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266))
        );

        // ------------------------------------------------

        address spookyOracleProxy = Upgrades.deployTransparentProxy(
            "SpookyOracle.sol",
            address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266),
            abi.encodeCall(SpookyOracle.initialize, (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266))
        );

        // ------------------------------------------------

        // TODO: add link to WETH

        address hodlMyBeerLendingProxy = Upgrades.deployTransparentProxy(
            "HodlMyBeerLending.sol",
            address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266),
            abi.encodeCall(HodlMyBeerLending.initialize, (address(0), address(magicETHProxy), address(spookyOracleProxy)))
        );

        // ------------------------------------------------

        console.log("proxyMagicETH at:         ", magicETHProxy);
        console.log("hodlMyBeerLendingProxy at:", hodlMyBeerLendingProxy);
        console.log("spookyOracleProxy at:     ", spookyOracleProxy);

        vm.stopBroadcast();
    }
}
