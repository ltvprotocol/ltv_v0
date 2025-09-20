// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract MorphoBlueMarketCalculation is Script {
    function run() public pure {
        address loanToken = address(0);
        address collateralToken = address(0);
        address oracle = address(0);
        address irm = address(0);
        uint256 lltv = 0;
        console.logBytes32(keccak256(abi.encode(loanToken, collateralToken, oracle, irm, lltv)));
    }
}
