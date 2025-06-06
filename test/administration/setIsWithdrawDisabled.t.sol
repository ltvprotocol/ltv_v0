// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import "./PrepareEachFunctionSuccessfulExecution.sol";

contract SetIsWithdrawDisabledTest is PrepareEachFunctionSuccessfulExecution {
    struct UserBalance {
        uint256 collateral;
        uint256 borrow;
        uint256 shares;
    }

    function getUserBalance(address user) public view returns (UserBalance memory) {
        return UserBalance({
            collateral: collateralToken.balanceOf(user),
            borrow: borrowToken.balanceOf(user),
            shares: ltv.balanceOf(user)
        });
    }

    function withdrawDisabledCalls(address user) public pure returns (bytes[] memory) {
        bytes[] memory selectors = new bytes[](9);
        uint256 amount = 1000;
        
        selectors[0] = abi.encodeCall(ILTV.executeLowLevelRebalanceShares, (-int256(amount)));
        selectors[1] = abi.encodeCall(ILTV.redeem, (amount, user, user));
        selectors[2] = abi.encodeCall(ILTV.withdraw, (amount, user, user));
        selectors[3] = abi.encodeCall(ILTV.redeemCollateral, (amount, user, user));
        selectors[4] = abi.encodeCall(ILTV.withdrawCollateral, (amount, user, user));
        selectors[5] = abi.encodeCall(ILTV.executeLowLevelRebalanceBorrow, (-int256(amount)));
        selectors[6] = abi.encodeCall(ILTV.executeLowLevelRebalanceBorrowHint, (-int256(amount), false));
        selectors[7] = abi.encodeCall(ILTV.executeLowLevelRebalanceCollateral, (-int256(amount)));
        selectors[8] = abi.encodeCall(ILTV.executeLowLevelRebalanceCollateralHint, (-int256(amount), false));
        return selectors;
    }

    function prepareWithdrawDisabledTest(address user) public {
        prepareEachFunctionSuccessfulExecution(user);
        
        ltv.setFutureRewardBorrowAssets(0);
        ltv.setFutureBorrowAssets(10000);
        ltv.setFutureCollateralAssets(10000); 
        ltv.setFutureRewardCollateralAssets(-100);
    }

    function test_checkSlot(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        bool isDisabled = ltv.isWithdrawDisabled();

        vm.startPrank(data.guardian);
        ltv.setIsWithdrawDisabled(!isDisabled);
        vm.stopPrank();

        assertEq(ltv.isWithdrawDisabled(), !isDisabled);
    }

    /// forge-config: default.fuzz.runs = 10
    function test_failIfWithdrawIsDisabledBatch(DefaultTestData memory data, address user) public {
        vm.assume(user != address(0));

        bytes[] memory calls = withdrawDisabledCalls(user);

        for (uint256 i = 0; i < calls.length; i++) {
            failIfWithdrawIsDisabled(data, user, calls[i]);
        }
    }

    function failIfWithdrawIsDisabled(DefaultTestData memory data, address user, bytes memory call)
        internal
        testWithPredefinedDefaultValues(data)
    {
        prepareWithdrawDisabledTest(user);

        vm.startPrank(data.guardian);
        ltv.setIsWithdrawDisabled(true);
        vm.stopPrank();

        vm.startPrank(user);
        (bool success, bytes memory result) = address(ltv).call(call);
        vm.stopPrank();

        assertEq(success, false);
        assertEq(result, abi.encodeWithSelector(IAdministrationErrors.WithdrawIsDisabled.selector));
    }

    /// forge-config: default.fuzz.runs = 10
    function test_passIfWithdrawIsEnabledBatch(DefaultTestData memory data, address user) public {
        vm.assume(user != address(0));

        bytes[] memory calls = withdrawDisabledCalls(user);

        for (uint256 i = 0; i < calls.length; i++) {
            passIfWithdrawIsEnabled(data, user, calls[i]);
        }
    }

    function passIfWithdrawIsEnabled(DefaultTestData memory data, address user, bytes memory call)
        internal
        testWithPredefinedDefaultValues(data)
    {
        prepareEachFunctionSuccessfulExecution(user);

        vm.startPrank(data.guardian);
        ltv.setIsWithdrawDisabled(false);
        vm.stopPrank();

        vm.startPrank(user);
        (bool success,) = address(ltv).call(call);
        vm.stopPrank();

        assertEq(success, true);
    }

    function test_failIfNotGuardian(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.guardian);
        vm.assume(user != address(0));

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGuardianInvalidCaller.selector, user));
        ltv.setIsWithdrawDisabled(true);
        vm.stopPrank();
    }
}