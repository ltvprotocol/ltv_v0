// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../utils/BaseTest.t.sol';

contract SetMaxGrowthFeeTest is BaseTest {
    function test_checkSlot(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint256 newMaxGrowthFee = 15 * 10 ** 15;
        vm.prank(defaultData.governor);
        ltv.setMaxGrowthFee(newMaxGrowthFee);

        assertEq(ltv.maxGrowthFee(), newMaxGrowthFee);
    }

    function test_zeroMaxGrowthFee(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        vm.prank(defaultData.governor);
        ltv.setMaxGrowthFee(0);

        uint256 tokenPriceBefore = ltv.convertToAssets(10**18);
        // increase total assets twice
        vm.prank(defaultData.owner);
        oracle.setAssetPrice(address(collateralToken), 2 * 10**18 * 5 / 4);
        // check token price increased twice, result is decreased due to virtual assets
        assertEq(ltv.convertToAssets(10**18), 2 * tokenPriceBefore - 10000);
    }

    function test_100PercentMaxGrowthFee(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        vm.prank(defaultData.governor);
        ltv.setMaxGrowthFee(10 ** 18);

        uint256 tokenPriceBefore = ltv.convertToAssets(10**18);
        // increase total assets twice
        vm.prank(defaultData.owner);
        oracle.setAssetPrice(address(collateralToken), 2 * 10**18 * 5 / 4);
        // check token price didn't change
        assertEq(ltv.convertToAssets(10**18), tokenPriceBefore);
    }

    function test_failIf42(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint256 invalidMaxGrowthFee = 42 * 10**18;
        vm.prank(defaultData.governor);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.InvalidMaxGrowthFee.selector, invalidMaxGrowthFee));
        ltv.setMaxGrowthFee(invalidMaxGrowthFee);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(user != defaultData.governor);

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setMaxGrowthFee(10**18);
    }
}
