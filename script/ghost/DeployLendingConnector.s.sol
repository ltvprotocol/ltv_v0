// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {console} from "forge-std/console.sol";
import {IHodlMyBeerLending} from "src/ghost/hodlmybeer/IHodlMyBeerLending.sol";
import {HodlLendingConnector} from "src/ghost/connectors/HodlLendingConnector.sol";
import {BaseScript} from "../utils/BaseScript.s.sol";

contract DeployHodlLendingConnector is BaseScript {
    function deploy() internal override {
        address hodlMyBeerLending = vm.envAddress("HODL_MY_BEER_LENDING");

        HodlLendingConnector connector =
            new HodlLendingConnector{salt: bytes32(0)}(IHodlMyBeerLending(hodlMyBeerLending));

        console.log("Hodl lending connector address: ", address(connector));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        address hodlMyBeerLending = vm.envAddress("HODL_MY_BEER_LENDING");

        return keccak256(abi.encodePacked(type(HodlLendingConnector).creationCode, abi.encode(hodlMyBeerLending)));
    }
}
