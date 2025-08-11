// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../utils/BaseScript.s.sol";
import "../../src/interfaces/ILendingConnector.sol";
import "../../src/ghost/connectors/HodlLendingConnector.sol";
import "forge-std/console.sol";

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
