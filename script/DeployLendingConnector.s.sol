// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import 'forge-std/Script.sol';
import '../src/interfaces/ILendingConnector.sol';
import '../src/ghost/connectors/HodlLendingConnector.sol';

contract DeployHodlLendingConnector is Script {
    function run() external {
        address hodlMyBeerLending = vm.envAddress('HODL_MY_BEER_LENDING');
        address collateralToken = vm.envAddress('COLLATERAL_TOKEN');
        address borrowToken = vm.envAddress('BORROW_TOKEN');

        vm.startBroadcast();
        HodlLendingConnector connector = new HodlLendingConnector(
            IERC20(collateralToken),
            IERC20(borrowToken),
            IHodlMyBeerLending(hodlMyBeerLending)
        );
        vm.stopBroadcast();

        console.log('Hodl lending connector address: ', address(connector));
    }
}
