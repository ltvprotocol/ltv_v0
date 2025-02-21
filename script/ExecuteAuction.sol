// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import 'forge-std/Script.sol';

import {GhostLTV} from '../src/ltv_lendings/GhostLTV.sol';

import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract ExecuteAuction is Script {
    function setUp() public {}

    function run() public {

        address ltv = vm.envAddress('LTV');
        address collateralToken = vm.envAddress('COLLATERAL_TOKEN');
        address borrowToken = vm.envAddress('BORROW_TOKEN');

        int256 threashold = 10**17;

        if (GhostLTV(ltv).futureBorrowAssets() > threashold) {

            IERC20 collateral = IERC20(collateralToken);

            int256 futureBorrowAssets = GhostLTV(ltv).futureBorrowAssets();
            int256 futureCollateralAssets = GhostLTV(ltv).futureBorrowAssets();

            uint256 collateralBalance = collateral.balanceOf(msg.sender);

            if (collateralBalance < uint256(futureCollateralAssets)) {
                console.log('Collateral balance is too low');
                return;
            }

            vm.startBroadcast(); // Start broadcasting transactions

            collateral.approve(ltv, collateralBalance);

            GhostLTV(ltv).executeAuctionBorrow(futureBorrowAssets);

            vm.stopBroadcast();

            console.log('Auction borrow executed');
        } else {
            if (GhostLTV(ltv).futureBorrowAssets() < -threashold) {

                IERC20 borrow = IERC20(borrowToken);

                int256 futureBorrowAssets = GhostLTV(ltv).futureBorrowAssets();

                uint256 borrowBalance = borrow.balanceOf(address(this));

                int256 futureCollateralAssets = GhostLTV(ltv).futureCollateralAssets();

                if (borrowBalance < uint256(-futureBorrowAssets)) {
                    console.log('Borrow balance is too low');
                    return;
                }

                vm.startBroadcast(); // Start broadcasting transactions

                borrow.approve(ltv, uint256(-futureBorrowAssets));

                GhostLTV(ltv).executeAuctionCollateral(-futureCollateralAssets);

                vm.stopBroadcast();

                console.log('Auction collateral executed');
            } else {
                console.log('No auction needed');
            }
        } 
    }
}
