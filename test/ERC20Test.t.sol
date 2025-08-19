// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BalancedTest} from "test/utils/BalancedTest.t.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract ERC20Test is BalancedTest {
    using SafeERC20 for IERC20;

    function test_totalSupply(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        assertEq(dummyLtv.totalSupply(), 10 ** 18);
    }

    function test_transferFrom(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        vm.startPrank(owner);
        dummyLtv.approve(user, 10 ** 17);
        vm.startPrank(user);
        IERC20(address(dummyLtv)).safeTransferFrom(owner, user, 10 ** 17);
        assertEq(dummyLtv.balanceOf(user), 10 ** 17);
    }

    function test_decimals(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        assertEq(dummyLtv.decimals(), 18);
    }

    function test_name(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        assertEq(dummyLtv.name(), "Dummy LTV");
    }

    function test_symbol(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        assertEq(dummyLtv.symbol(), "DLTV");
    }

    function test_approve(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        vm.stopPrank();
        vm.startPrank(owner);

        dummyLtv.approve(user, 10 ** 18);

        assertEq(dummyLtv.allowance(owner, user), 10 ** 18);
    }
}
