// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract SetMaxGrowthFeeTest is BaseTest {
    function test_checkSlot(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint16 newMaxGrowthFeeDividend = 15;
        uint16 newMaxGrowthFeeDivider = 1000;
        vm.prank(defaultData.governor);
        ltv.setMaxGrowthFee(newMaxGrowthFeeDividend, newMaxGrowthFeeDivider);

        assertEq(ltv.maxGrowthFeeDividend(), newMaxGrowthFeeDividend);
        assertEq(ltv.maxGrowthFeeDivider(), newMaxGrowthFeeDivider);
    }

    function test_zeroMaxGrowthFee(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.prank(defaultData.governor);
        ltv.setMaxGrowthFee(0, 1); // 0% fee

        uint256 tokenPriceBefore = ltv.convertToAssets(10 ** 18);
        // increase total assets twice
        vm.prank(defaultData.owner);
        oracle.setAssetPrice(address(collateralToken), 2 * 10 ** 18 * 5 / 4);
        // check token price increased twice, result is decreased due to virtual assets
        assertEq(ltv.convertToAssets(10 ** 18), 2 * tokenPriceBefore - 10000);
    }

    function test_100PercentMaxGrowthFee(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.prank(defaultData.governor);
        ltv.setMaxGrowthFee(1, 1); // 100% fee

        uint256 tokenPriceBefore = ltv.convertToAssets(10 ** 18);
        // increase total assets twice
        vm.prank(defaultData.owner);
        oracle.setAssetPrice(address(collateralToken), 2 * 10 ** 18 * 5 / 4);
        // check token price didn't change
        assertEq(ltv.convertToAssets(10 ** 18), tokenPriceBefore);
    }

    function test_failIfTooBig(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 invalidDividend = type(uint16).max;
        uint16 invalidDivider = 1;
        vm.prank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(IAdministrationErrors.InvalidMaxGrowthFee.selector, invalidDividend, invalidDivider)
        );
        ltv.setMaxGrowthFee(invalidDividend, invalidDivider);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setMaxGrowthFee(1, 1); // 100% fee
    }
}
