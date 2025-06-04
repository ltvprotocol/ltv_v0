// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import "./PrepareEachFunctionSuccessfulExecution.sol";

contract SetIsDepositDisabledTest is PrepareEachFunctionSuccessfulExecution {
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

    function checkTokensReceived(UserBalance memory initialBalance, UserBalance memory currentBalance) internal pure {
        require(
            initialBalance.collateral < currentBalance.collateral || initialBalance.borrow < currentBalance.borrow
                || initialBalance.shares < currentBalance.shares
        );
    }

    function depositDisabledCalls(address user) public pure returns (bytes[] memory) {
        bytes[] memory selectors = new bytes[](9);
        uint256 amount = 1000;
        selectors[0] = abi.encodeCall(ILTV.executeLowLevelRebalanceShares, (int256(amount)));
        selectors[1] = abi.encodeCall(ILTV.executeLowLevelRebalanceBorrow, (int256(amount)));
        selectors[2] = abi.encodeCall(ILTV.executeLowLevelRebalanceBorrowHint, (int256(amount), true));
        selectors[3] = abi.encodeCall(ILTV.executeLowLevelRebalanceCollateral, (int256(amount)));
        selectors[4] = abi.encodeCall(ILTV.executeLowLevelRebalanceCollateralHint, (int256(amount), true));
        selectors[5] = abi.encodeCall(ILTV.deposit, (amount, user));
        selectors[6] = abi.encodeCall(ILTV.depositCollateral, (amount, user));
        selectors[7] = abi.encodeCall(ILTV.mint, (amount, user));
        selectors[8] = abi.encodeCall(ILTV.mintCollateral, (amount, user));
        return selectors;
    }

    function prepareDepositDisabledTest(address user) public {
        prepareEachFunctionSuccessfulExecution(user);
    }

    function test_checkSlot(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        bool isDisabled = ltv.isDepositDisabled();

        vm.startPrank(data.guardian);
        ltv.setIsDepositDisabled(!isDisabled);
        vm.stopPrank();

        assertEq(ltv.isDepositDisabled(), !isDisabled);
    }

    function test_failIfDepositIsDisabledBatch(DefaultTestData memory data, address user) public {
        vm.assume(user != address(0));
        vm.assume(user != data.owner);
        vm.assume(user != data.guardian);
        vm.assume(user != data.governor);
        vm.assume(user != data.emergencyDeleverager);
        vm.assume(user != data.feeCollector);

        bytes[] memory calls = depositDisabledCalls(user);

        for (uint256 i = 0; i < calls.length; i++) {
            failIfDepositIsDisabled(data, user, calls[i]);
        }
    }

    function failIfDepositIsDisabled(DefaultTestData memory data, address user, bytes memory call)
        internal
        testWithPredefinedDefaultValues(data)
    {
        prepareDepositDisabledTest(user);

        vm.startPrank(data.guardian);
        ltv.setIsDepositDisabled(true);
        vm.stopPrank();

        vm.startPrank(user);
        (bool success, bytes memory result) = address(ltv).call(call);
        vm.stopPrank();

        assertEq(success, false);
        assertEq(result, abi.encodeWithSelector(IAdministrationErrors.DepositIsDisabled.selector));
    }

    function test_passIfDepositIsEnabledBatch(DefaultTestData memory data, address user) public {
        vm.assume(user != address(0));
        vm.assume(user != data.owner);
        vm.assume(user != data.guardian);
        vm.assume(user != data.governor);
        vm.assume(user != data.emergencyDeleverager);
        vm.assume(user != data.feeCollector);

        bytes[] memory calls = depositDisabledCalls(user);

        for (uint256 i = 0; i < calls.length; i++) {
            passIfDepositIsEnabled(data, user, calls[i]);
        }
    }

    function passIfDepositIsEnabled(DefaultTestData memory data, address user, bytes memory call)
        internal
        testWithPredefinedDefaultValues(data)
    {
        prepareDepositDisabledTest(user);

        vm.startPrank(data.guardian);
        ltv.setIsDepositDisabled(false);
        vm.stopPrank();

        UserBalance memory initialBalance = getUserBalance(user);

        vm.startPrank(user);
        (bool success,) = address(ltv).call(call);
        vm.stopPrank();

        assertEq(success, true);
        checkTokensReceived(initialBalance, getUserBalance(user));
    }

    function test_failIfNotGuardian(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.guardian);
        vm.assume(user != address(0));

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGuardianInvalidCaller.selector, user));
        ltv.setIsDepositDisabled(true);
        vm.stopPrank();
    }
}
