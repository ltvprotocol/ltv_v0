// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './utils/BaseTest.t.sol';

contract DeleverageAndWithdrawTest is BaseTest {
    function test_leave_lending(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        vm.stopPrank();
        address emergencyDeleverager = ILTV(address(dummyLTV)).emergencyDeleverager();
        vm.startPrank(emergencyDeleverager);
        deal(address(borrowToken), address(emergencyDeleverager), type(uint112).max);
        borrowToken.approve(address(dummyLTV), type(uint112).max);
        dummyLTV.deleverageAndWithdraw(dummyLTV.getRealBorrowAssets(true), 5 * 10 ** 15);

        // total assets were reduced for 6% according to target LTV = 3/4 and 2% fee for deleverage
        assertEq(dummyLTV.totalAssets(), 985 * 10 ** 15 + 100);

        assertEq(dummyLTV.withdrawCollateral(985 * 10 ** 14, address(owner), address(owner)), 2 * 10 ** 17);
        dummyLTV.redeemCollateral(2 * 10 ** 17, address(owner), address(owner));
    }

    function test_deleverageAndWithdraw(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        uint256 deleverageFee = 1 * 10 ** 16; // 1%
        uint256 closeAmount = 3 * 10 ** 18;

        // Should revert if not deleverager
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyEmergencyDeleveragerInvalidCaller.selector, user));
        ILTV(address(dummyLTV)).deleverageAndWithdraw(closeAmount, deleverageFee);

        address emergencyDeleverager = ILTV(address(dummyLTV)).emergencyDeleverager();
        // Should revert if fee too high
        vm.startPrank(emergencyDeleverager);
        uint256 tooBigFee = ILTV(address(dummyLTV)).maxDeleverageFee() + 1;
        vm.expectRevert(
            abi.encodeWithSelector(IAdministrationErrors.ExceedsMaxDeleverageFee.selector, tooBigFee, ILTV(address(dummyLTV)).maxDeleverageFee())
        );
        deal(address(borrowToken), address(emergencyDeleverager), closeAmount);
        borrowToken.approve(address(dummyLTV), closeAmount);

        ILTV(address(dummyLTV)).deleverageAndWithdraw(closeAmount, deleverageFee);
    }
}
