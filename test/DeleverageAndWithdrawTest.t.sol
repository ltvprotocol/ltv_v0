// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BalancedTest} from "./utils/BalancedTest.t.sol";
import {ILTV} from "../src/interfaces/ILTV.sol";
import {IAdministrationErrors} from "../src/errors/IAdministrationErrors.sol";

contract DeleverageAndWithdrawTest is BalancedTest {
    function test_leave_lending(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        address emergencyDeleverager = ILTV(address(dummyLtv)).emergencyDeleverager();
        vm.startPrank(emergencyDeleverager);
        deal(address(borrowToken), address(emergencyDeleverager), type(uint112).max);
        borrowToken.approve(address(dummyLtv), type(uint112).max);
        dummyLtv.deleverageAndWithdraw(dummyLtv.getRealBorrowAssets(true), uint16(1), uint16(200)); // 0.5% fee
        vm.stopPrank();

        // total assets were reduced for 1.5%, since 0.5% fee with 4x leverage (when 4x leverage,
        // it's 4x collateral and 3x borrow assets. For exchanging borrow assets user receives reward)
        assertEq(dummyLtv.totalAssets(), 985 * 10 ** 15);

        vm.startPrank(owner);
        assertEq(dummyLtv.withdrawCollateral(985 * 10 ** 14, address(owner), address(owner)), 2 * 10 ** 17);
        dummyLtv.redeemCollateral(2 * 10 ** 17, address(owner), address(owner));
    }

    function test_deleverageAndWithdraw(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        address emergencyDeleverager = ILTV(address(dummyLtv)).emergencyDeleverager();
        vm.assume(emergencyDeleverager != user);
        uint16 deleverageFeeDividend = 1; // 1%
        uint16 deleverageFeeDivider = 100;
        uint256 closeAmount = 3 * 10 ** 18;

        // Should revert if not deleverager
        vm.expectRevert(
            abi.encodeWithSelector(IAdministrationErrors.OnlyEmergencyDeleveragerInvalidCaller.selector, user)
        );
        ILTV(address(dummyLtv)).deleverageAndWithdraw(closeAmount, deleverageFeeDividend, deleverageFeeDivider);

        // Should revert if fee too high
        vm.startPrank(emergencyDeleverager);
        uint16 maxDividend = ILTV(address(dummyLtv)).maxDeleverageFeeDividend();
        uint16 maxDivider = ILTV(address(dummyLtv)).maxDeleverageFeeDivider();
        uint16 tooHighDividend = maxDividend + 1; // This will make the fee higher than max

        deal(address(borrowToken), address(emergencyDeleverager), closeAmount);
        borrowToken.approve(address(dummyLtv), closeAmount);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.ExceedsMaxDeleverageFee.selector,
                tooHighDividend,
                maxDivider,
                maxDividend,
                maxDivider
            )
        );
        ILTV(address(dummyLtv)).deleverageAndWithdraw(closeAmount, tooHighDividend, maxDivider);
    }
}
