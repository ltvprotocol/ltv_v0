// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {DefaultTestData} from "./utils/BaseTest.t.sol";
import {PrepareEachFunctionSuccessfulExecution} from "./administration/PrepareEachFunctionSuccessfulExecution.sol";
import {WhitelistRegistry} from "../src/elements/WhitelistRegistry.sol";

contract ERC20CompatibilityTest is PrepareEachFunctionSuccessfulExecution {
    struct CallWithCaller {
        bytes callData;
        address caller;
    }

    address testUser = makeAddr("testUser");
    address testUser2 = makeAddr("testUser2");

    function erc20CallsWithCaller(address user, address user2) public pure returns (CallWithCaller[] memory) {
        CallWithCaller[] memory calls = new CallWithCaller[](6);
        uint256 amount = 100;
        uint256 i = 0;

        calls[i++] = CallWithCaller(abi.encodeCall(IERC20.totalSupply, ()), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC20.balanceOf, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC20.transfer, (user2, amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC20.approve, (user2, amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC20.allowance, (user, user2)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC20.transferFrom, (user, user2, amount)), user2);

        return calls;
    }

    function initExecutionEnvironment(DefaultTestData memory data) public {
        vm.assume(data.owner != address(0));
        vm.assume(data.guardian != address(0));
        vm.assume(data.governor != address(0));
        vm.assume(data.emergencyDeleverager != address(0));
        vm.assume(data.feeCollector != address(0));

        prepareEachFunctionSuccessfulExecution(testUser);

        deal(address(borrowToken), data.emergencyDeleverager, type(uint112).max);
        deal(address(collateralToken), data.emergencyDeleverager, type(uint112).max);

        vm.startPrank(data.emergencyDeleverager);
        borrowToken.approve(address(ltv), type(uint112).max);
        collateralToken.approve(address(ltv), type(uint112).max);
        vm.stopPrank();

        WhitelistRegistry registry = new WhitelistRegistry(data.owner, address(0));
        vm.prank(data.governor);
        ltv.setWhitelistRegistry(address(registry));
    }

    function test_everyFunctionExecutes(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        initExecutionEnvironment(data);

        CallWithCaller[] memory calls = erc20CallsWithCaller(testUser, testUser2);

        for (uint256 i = 0; i < calls.length; i++) {
            vm.prank(calls[i].caller);
            (bool success,) = address(ltv).call(calls[i].callData);

            require(success);
        }
    }

    function test_transferExecutesAndEmitsEvent(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        initExecutionEnvironment(data);

        uint256 amount = 1000;
        deal(address(ltv), testUser, amount);

        vm.prank(testUser);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(testUser, testUser2, amount);
        bool success = ltv.transfer(testUser2, amount);

        require(success);
    }

    function test_approveExecutesAndEmitsEvent(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        initExecutionEnvironment(data);

        uint256 amount = 1000;

        vm.prank(testUser);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Approval(testUser, testUser2, amount);
        bool success = ltv.approve(testUser2, amount);

        require(success);
    }

    function test_transferFromExecutesAndEmitsEvent(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        initExecutionEnvironment(data);

        uint256 amount = 1000;
        deal(address(ltv), testUser, amount);

        vm.prank(testUser);
        ltv.approve(testUser2, amount);

        vm.prank(testUser2);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(testUser, testUser2, amount);
        bool success = ltv.transferFrom(testUser, testUser2, amount);

        require(success);
    }
}
