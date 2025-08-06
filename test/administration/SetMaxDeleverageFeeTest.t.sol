// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";

contract SetMaxDeleverageFeeTest is BaseTest {
    function test_failIfNotEmergencyDeleverager(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.emergencyDeleverager);
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAdministrationErrors.OnlyEmergencyDeleveragerInvalidCaller.selector, user)
        );
        ltv.deleverageAndWithdraw(0, 0);
    }

    function test_failIfGreaterFeeInDeleverageAndWithdraw(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint24 maxDeleverageFeex23 = ltv.maxDeleverageFeex23();
        uint256 deleverageFee = maxDeleverageFeex23 + 1;
        vm.startPrank(defaultData.emergencyDeleverager);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.ExceedsMaxDeleverageFee.selector, deleverageFee, maxDeleverageFeex23
            )
        );
        ltv.deleverageAndWithdraw(0, deleverageFee);
    }

    function test_worksWithLessFeeInDeleverageAndWithdraw(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint256 deleverageFeex23 = ltv.maxDeleverageFeex23();

        uint256 borrowAssets = ILendingConnector(ltv.getLendingConnector()).getRealBorrowAssets(true, "");
        deal(address(borrowToken), defaultData.emergencyDeleverager, borrowAssets);
        vm.startPrank(defaultData.emergencyDeleverager);
        borrowToken.approve(address(ltv), borrowAssets);

        ltv.deleverageAndWithdraw(borrowAssets, deleverageFeex23);

        uint256 zeroFeeAssets = borrowAssets * ltv.oracleConnector().getPriceBorrowOracle()
            / ltv.oracleConnector().getPriceCollateralOracle();
        // 2% fee with 3/4 ltv gives 6% of total assets as fee
        assertEq(collateralToken.balanceOf(defaultData.emergencyDeleverager), zeroFeeAssets + 10 ** 16);
    }

    function test_setAndCheckStorageSlot(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint128 newMaxDeleverageFeex23 = 2**23 / 20; // 0.05
        vm.startPrank(defaultData.governor);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.MaxDeleverageFeeChanged(ltv.maxDeleverageFeex23(), newMaxDeleverageFeex23);
        ltv.setMaxDeleverageFeex23(newMaxDeleverageFeex23);

        assertEq(ltv.maxDeleverageFeex23(), newMaxDeleverageFeex23);
    }

    function test_canDeleverageWithZeroMaxFee(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        assertEq(collateralToken.balanceOf(defaultData.emergencyDeleverager), 0);

        uint128 newMaxDeleverageFeex23 = 0;
        vm.startPrank(defaultData.governor);
        ltv.setMaxDeleverageFeex23(newMaxDeleverageFeex23);

        uint256 borrowAssets = ILendingConnector(ltv.getLendingConnector()).getRealBorrowAssets(true, "");
        deal(address(borrowToken), defaultData.emergencyDeleverager, borrowAssets);
        vm.startPrank(defaultData.emergencyDeleverager);
        borrowToken.approve(address(ltv), borrowAssets);

        // Should be able to deleverage with 0 fee
        ltv.deleverageAndWithdraw(borrowAssets, 0);
        assertEq(
            collateralToken.balanceOf(defaultData.emergencyDeleverager),
            (borrowAssets * ltv.oracleConnector().getPriceBorrowOracle())
                / ltv.oracleConnector().getPriceCollateralOracle()
        );
    }

    function test_passIfOne(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint128 newMaxDeleverageFeex23 = uint128(2**23); // 1.0
        vm.startPrank(defaultData.governor);
        ltv.setMaxDeleverageFeex23(newMaxDeleverageFeex23);
        assertEq(ltv.maxDeleverageFeex23(), newMaxDeleverageFeex23);
    }

    function test_failIfFortyTwo(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint128 newMaxDeleverageFeex23 = uint128(42 * 2**23);
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(IAdministrationErrors.InvalidMaxDeleverageFee.selector, newMaxDeleverageFeex23)
        );
        ltv.setMaxDeleverageFeex23(newMaxDeleverageFeex23);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        uint128 newMaxDeleverageFeex23 = uint128(ltv.maxDeleverageFeex23());
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setMaxDeleverageFeex23(newMaxDeleverageFeex23);
    }
}
