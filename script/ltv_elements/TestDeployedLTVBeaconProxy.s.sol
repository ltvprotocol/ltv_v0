// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import "../../src/interfaces/ILTV.sol";
import "forge-std/StdCheats.sol";
import "forge-std/Script.sol";
import "forge-std/interfaces/IERC20.sol";
import "forge-std/StdAssertions.sol";

contract TestDeployedOnForkLTVBeaconProxy is Script, StdCheats, StdAssertions {
    function run() public {
        vm.createSelectFork("http://127.0.0.1:8545");

        ILTV ltv = ILTV(vm.envAddress("LTV_BEACON_PROXY"));
        address collateralToken = ltv.collateralToken();
        address random = makeAddr("random");
        vm.startPrank(random);
        deal(collateralToken, random, type(uint256).max);
        IERC20(collateralToken).approve(address(ltv), type(uint256).max);
        int256 maxLowLevelRebalanceCollateral = ltv.maxLowLevelRebalanceCollateral();
        ltv.executeLowLevelRebalanceCollateralHint(maxLowLevelRebalanceCollateral, true);

        address borrowToken = ltv.borrowToken();
        ltv.withdraw(ltv.maxWithdraw(random), random, random);
        assertGt(IERC20(borrowToken).balanceOf(random), 0);
        assertGt(ltv.balanceOf(random), 0);
    }
}