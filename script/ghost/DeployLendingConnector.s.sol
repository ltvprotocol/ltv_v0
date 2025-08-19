// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IHodlMyBeerLending} from "src/ghost/hodlmybeer/IHodlMyBeerLending.sol";
import {HodlLendingConnector} from "src/ghost/connectors/HodlLendingConnector.sol";
import {BaseScript} from "../utils/BaseScript.s.sol";

contract DeployHodlLendingConnector is BaseScript {
    function deploy() internal override {
        address hodlMyBeerLending = vm.envAddress("HODL_MY_BEER_LENDING");
        address collateralToken = vm.envAddress("COLLATERAL_ASSET");
        address borrowToken = vm.envAddress("BORROW_ASSET");

        HodlLendingConnector connector = new HodlLendingConnector{salt: bytes32(0)}(
            IERC20(collateralToken), IERC20(borrowToken), IHodlMyBeerLending(hodlMyBeerLending)
        );

        console.log("Hodl lending connector address: ", address(connector));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        address hodlMyBeerLending = vm.envAddress("HODL_MY_BEER_LENDING");
        address collateralToken = vm.envAddress("COLLATERAL_ASSET");
        address borrowToken = vm.envAddress("BORROW_ASSET");

        return keccak256(
            abi.encodePacked(
                type(HodlLendingConnector).creationCode, abi.encode(collateralToken, borrowToken, hodlMyBeerLending)
            )
        );
    }
}
