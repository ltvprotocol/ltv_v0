// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import 'forge-std/Script.sol';
import '../src/LTV.sol';

// LTV=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 forge script --fork-url localhost:8545 script/Calculator.sol
contract Calculator is Script {
    function run() external view {
        LTV ltv = LTV(vm.envAddress('LTV'));

        int256 borrow = ltv.futureBorrowAssets() + ltv.futureRewardBorrowAssets() + int256(ltv.getRealBorrowAssets());
        int256 collateral = ltv.futureCollateralAssets() + ltv.futureRewardCollateralAssets() + int256(ltv.getRealCollateralAssets());

        console.log('future borrow assets', ltv.futureBorrowAssets());
        console.log('future reward borrow assets', ltv.futureRewardBorrowAssets());
        console.log('real borrow assets', ltv.getRealBorrowAssets());
        console.log('future collateral assets', ltv.futureCollateralAssets());
        console.log('future reward collateral assets', ltv.futureRewardCollateralAssets());
        console.log('real collateral assets', ltv.getRealCollateralAssets());
        console.log("borrow: ", borrow);
        console.log("collateral: ", collateral);
        console.log("ltv diff:", collateral * 3 - borrow * 4);
        console.log("price", ltv.convertToShares(10**18));
    }
}