// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./utils/BalancedTest.t.sol";

contract DeleverageAndWithdrawTest is BalancedTest {
    function test_leave_lending(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        address emergencyDeleverager = ILTV(address(dummyLTV)).emergencyDeleverager();
        vm.startPrank(emergencyDeleverager);
        deal(address(borrowToken), address(emergencyDeleverager), type(uint112).max);
        borrowToken.approve(address(dummyLTV), type(uint112).max);
        dummyLTV.deleverageAndWithdraw(dummyLTV.getRealBorrowAssets(true), 5 * 10 ** 15);
        vm.stopPrank();

        // total assets were reduced for 0.5%
        assertEq(dummyLTV.totalAssets(), 995 * 10 ** 15);

        vm.startPrank(owner);
        assertEq(dummyLTV.withdrawCollateral(995 * 10 ** 14, address(owner), address(owner)), 2 * 10 ** 17);
        dummyLTV.redeemCollateral(2 * 10 ** 17, address(owner), address(owner));
    }

    function test_deleverageAndWithdraw(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        address emergencyDeleverager = ILTV(address(dummyLTV)).emergencyDeleverager();
        vm.assume(emergencyDeleverager != user);
        uint24 deleverageFee = uint24(2**23) / 100; // 1%
        uint256 closeAmount = 3 * 10 ** 18;

        // Should revert if not deleverager
        vm.expectRevert(
            abi.encodeWithSelector(IAdministrationErrors.OnlyEmergencyDeleveragerInvalidCaller.selector, user)
        );
        ILTV(address(dummyLTV)).deleverageAndWithdraw(closeAmount, deleverageFee);

        // Should revert if fee too high
        vm.startPrank(emergencyDeleverager);
        uint24 tooBigFee = uint24(ILTV(address(dummyLTV)).maxDeleverageFeex23()) + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.ExceedsMaxDeleverageFee.selector,
                tooBigFee,
                ILTV(address(dummyLTV)).maxDeleverageFeex23()
            )
        );
        deal(address(borrowToken), address(emergencyDeleverager), closeAmount);
        borrowToken.approve(address(dummyLTV), closeAmount);

        ILTV(address(dummyLTV)).deleverageAndWithdraw(closeAmount, deleverageFee);
    }
}
