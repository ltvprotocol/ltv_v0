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
        ltv.deleverageAndWithdraw(0, 0, 1); // 0% fee
    }

    function test_failIfGreaterFeeInDeleverageAndWithdraw(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 maxDeleverageFeeDividend = ltv.maxDeleverageFeeDividend();
        uint16 maxDeleverageFeeDivider = ltv.maxDeleverageFeeDivider();
        uint16 tooHighDividend = maxDeleverageFeeDividend + 1; // This will exceed the max fee
        vm.startPrank(defaultData.emergencyDeleverager);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.ExceedsMaxDeleverageFee.selector,
                tooHighDividend,
                maxDeleverageFeeDivider,
                maxDeleverageFeeDividend,
                maxDeleverageFeeDivider
            )
        );
        ltv.deleverageAndWithdraw(0, tooHighDividend, maxDeleverageFeeDivider);
    }

    function test_worksWithLessFeeInDeleverageAndWithdraw(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 deleverageFeeDividend = ltv.maxDeleverageFeeDividend();
        uint16 deleverageFeeDivider = ltv.maxDeleverageFeeDivider();

        uint256 borrowAssets = ILendingConnector(ltv.getLendingConnector()).getRealBorrowAssets(true, "");
        deal(address(borrowToken), defaultData.emergencyDeleverager, borrowAssets);
        vm.startPrank(defaultData.emergencyDeleverager);
        borrowToken.approve(address(ltv), borrowAssets);

        ltv.deleverageAndWithdraw(borrowAssets, deleverageFeeDividend, deleverageFeeDivider);

        uint256 zeroFeeAssets = borrowAssets * ltv.oracleConnector().getPriceBorrowOracle()
            / ltv.oracleConnector().getPriceCollateralOracle();
        // 2% fee with 3/4 ltv gives 6% of total assets as fee
        assertEq(collateralToken.balanceOf(defaultData.emergencyDeleverager), zeroFeeAssets + 10 ** 16);
    }

    function test_setAndCheckStorageSlot(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 newMaxDeleverageFeeDividend = 1; // 5%
        uint16 newMaxDeleverageFeeDivider = 20;
        vm.startPrank(defaultData.governor);
        vm.expectEmit(true, true, true, true, address(ltv));
        emit IAdministrationEvents.MaxDeleverageFeeChanged(
            ltv.maxDeleverageFeeDividend(),
            ltv.maxDeleverageFeeDivider(),
            newMaxDeleverageFeeDividend,
            newMaxDeleverageFeeDivider
        );
        ltv.setMaxDeleverageFee(newMaxDeleverageFeeDividend, newMaxDeleverageFeeDivider);

        assertEq(ltv.maxDeleverageFeeDividend(), newMaxDeleverageFeeDividend);
        assertEq(ltv.maxDeleverageFeeDivider(), newMaxDeleverageFeeDivider);
    }

    function test_canDeleverageWithZeroMaxFee(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        assertEq(collateralToken.balanceOf(defaultData.emergencyDeleverager), 0);

        uint16 newMaxDeleverageFeeDividend = 0; // 0% fee
        uint16 newMaxDeleverageFeeDivider = 1;
        vm.startPrank(defaultData.governor);
        ltv.setMaxDeleverageFee(newMaxDeleverageFeeDividend, newMaxDeleverageFeeDivider);

        uint256 borrowAssets = ILendingConnector(ltv.getLendingConnector()).getRealBorrowAssets(true, "");
        deal(address(borrowToken), defaultData.emergencyDeleverager, borrowAssets);
        vm.startPrank(defaultData.emergencyDeleverager);
        borrowToken.approve(address(ltv), borrowAssets);

        // Should be able to deleverage with 0 fee
        ltv.deleverageAndWithdraw(borrowAssets, 0, 1);
        assertEq(
            collateralToken.balanceOf(defaultData.emergencyDeleverager),
            (borrowAssets * ltv.oracleConnector().getPriceBorrowOracle())
                / ltv.oracleConnector().getPriceCollateralOracle()
        );
    }

    function test_passIfOne(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        uint16 newMaxDeleverageFeeDividend = 1; // 100% fee
        uint16 newMaxDeleverageFeeDivider = 1;
        vm.startPrank(defaultData.governor);
        ltv.setMaxDeleverageFee(newMaxDeleverageFeeDividend, newMaxDeleverageFeeDivider);
        assertEq(ltv.maxDeleverageFeeDividend(), newMaxDeleverageFeeDividend);
        assertEq(ltv.maxDeleverageFeeDivider(), newMaxDeleverageFeeDivider);
    }

    function test_failIfTooBig(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint16 newMaxDeleverageFeeDividend = 10; // Invalid: 10/5 = 200%
        uint16 newMaxDeleverageFeeDivider = 5;
        vm.startPrank(defaultData.governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidMaxDeleverageFee.selector,
                newMaxDeleverageFeeDividend,
                newMaxDeleverageFeeDivider
            )
        );
        ltv.setMaxDeleverageFee(newMaxDeleverageFeeDividend, newMaxDeleverageFeeDivider);
    }

    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        uint16 newMaxDeleverageFeeDividend = ltv.maxDeleverageFeeDividend();
        uint16 newMaxDeleverageFeeDivider = ltv.maxDeleverageFeeDivider();
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setMaxDeleverageFee(newMaxDeleverageFeeDividend, newMaxDeleverageFeeDivider);
    }
}
