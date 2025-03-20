// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import 'forge-std/Script.sol';
import '../src/LTV.sol';

// LTV=0xE2A7f267124AC3E4131f27b9159c78C521A44F3c forge script --fork-url $RPC_SEPOLIA script/Calculator.sol
contract Calculator is Script {
    function run() external view {
        LTV ltv = LTV(vm.envAddress('LTV'));

        int256 futureBorrowAssets = ltv.futureBorrowAssets();
        int256 futureRewardBorrowAssets = ltv.futureRewardBorrowAssets();
        int256 realBorrowAssets = int256(ltv.getRealBorrowAssets());
        int256 futureCollateralAssets = ltv.futureCollateralAssets();
        int256 futureRewardCollateralAssets = ltv.futureRewardCollateralAssets();
        int256 realCollateralAssets = int256(ltv.getRealCollateralAssets());

        int256 borrow = futureBorrowAssets + futureRewardBorrowAssets + realBorrowAssets;
        int256 collateral = futureCollateralAssets + futureRewardCollateralAssets + realCollateralAssets;

        console.log('future borrow assets', futureBorrowAssets);
        console.log('future reward borrow assets', futureRewardBorrowAssets);
        console.log('real borrow assets', realBorrowAssets);
        console.log('future collateral assets', futureCollateralAssets);
        console.log('future reward collateral assets', futureRewardCollateralAssets);
        console.log('real collateral assets', realCollateralAssets);
        console.log("borrow: ", borrow);
        console.log("collateral: ", collateral);
        console.log("ltv diff:", collateral * 3 - borrow * 4);
        console.log("price", ltv.convertToShares(10**18));
    }
}