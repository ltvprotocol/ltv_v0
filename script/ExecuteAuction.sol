// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'forge-std/Script.sol';

import {LTV} from '../src/LTV.sol';

import {IERC20} from 'forge-std/interfaces/IERC20.sol';
// LTV=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 COLLATERAL_TOKEN=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 BORROW_TOKEN=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 forge script --fork-url localhost:8545 script/ExecuteAuction.sol --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
contract ExecuteAuction is Script {
    function setUp() public {}

    function run() public {

        LTV ltv = LTV(vm.envAddress('LTV'));
        address collateralToken = vm.envAddress('COLLATERAL_TOKEN');
        address borrowToken = vm.envAddress('BORROW_TOKEN');

        int256 threashold = 10**17;

        if (ltv.futureBorrowAssets() > threashold) {

            IERC20 collateral = IERC20(collateralToken);

            int256 futureBorrowAssets = ltv.futureBorrowAssets();
            int256 futureCollateralAssets = ltv.futureBorrowAssets();

            uint256 collateralBalance = collateral.balanceOf(msg.sender);

            if (collateralBalance < uint256(futureCollateralAssets)) {
                console.log('Collateral balance is too low');
                return;
            }

            vm.startBroadcast(); // Start broadcasting transactions

            collateral.approve(address(ltv), collateralBalance);

            ltv.executeAuctionBorrow(-futureBorrowAssets);

            vm.stopBroadcast();

            console.log('Auction borrow executed');
        } else {
            if (ltv.futureBorrowAssets() < -threashold) {

                IERC20 borrow = IERC20(borrowToken);

                int256 futureBorrowAssets = ltv.futureBorrowAssets();

                uint256 borrowBalance = borrow.balanceOf(msg.sender);

                int256 futureCollateralAssets = ltv.futureCollateralAssets();

                if (borrowBalance < uint256(-futureBorrowAssets)) {
                    console.log('Borrow balance is too low');
                    return;
                }

                vm.startBroadcast(); // Start broadcasting transactions

                borrow.approve(address(ltv), uint256(-futureBorrowAssets));

                ltv.executeAuctionCollateral(-futureCollateralAssets);

                vm.stopBroadcast();

                console.log('Auction collateral executed');
            } else {
                console.log('No auction needed');
            }
        } 
    }
}
