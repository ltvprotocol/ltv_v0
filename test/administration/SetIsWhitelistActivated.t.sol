// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, DefaultTestData} from "test/utils/BaseTest.t.sol";
import {ILTV} from "src/interfaces/ILTV.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";
import {WhitelistRegistry} from "src/elements/WhitelistRegistry.sol";
import {PrepareEachFunctionSuccessfulExecution} from "test/administration/PrepareEachFunctionSuccessfulExecution.sol";

contract SetIsWhitelistActivatedTest is PrepareEachFunctionSuccessfulExecution {
    WhitelistRegistry registry;

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
                || initialBalance.shares < currentBalance.shares,
            "Didn't receive any token"
        );
    }

    function whitelistCalls(address user) public pure returns (bytes[] memory) {
        bytes[] memory selectors = new bytes[](15);
        uint256 amount = 1000;
        selectors[0] = abi.encodeCall(ILTV.deposit, (amount, user));
        selectors[1] = abi.encodeCall(ILTV.mint, (amount, user));
        selectors[2] = abi.encodeCall(ILTV.redeem, (amount, user, user));
        selectors[3] = abi.encodeCall(ILTV.withdraw, (amount, user, user));
        selectors[4] = abi.encodeCall(ILTV.depositCollateral, (amount, user));
        selectors[5] = abi.encodeCall(ILTV.mintCollateral, (amount, user));
        selectors[6] = abi.encodeCall(ILTV.redeemCollateral, (amount, user, user));
        selectors[7] = abi.encodeCall(ILTV.withdrawCollateral, (amount, user, user));
        selectors[8] = abi.encodeCall(ILTV.executeAuctionBorrow, (int256(amount)));
        selectors[9] = abi.encodeCall(ILTV.executeAuctionCollateral, (int256(amount)));
        selectors[10] = abi.encodeCall(ILTV.executeLowLevelRebalanceBorrow, (int256(amount)));
        selectors[11] = abi.encodeCall(ILTV.executeLowLevelRebalanceBorrowHint, (int256(amount), true));
        selectors[12] = abi.encodeCall(ILTV.executeLowLevelRebalanceCollateral, (int256(amount)));
        selectors[13] = abi.encodeCall(ILTV.executeLowLevelRebalanceCollateralHint, (int256(amount), true));
        selectors[14] = abi.encodeCall(ILTV.executeLowLevelRebalanceShares, (int256(amount)));
        return selectors;
    }

    function prepareWhitelistDepositWithdrawTest(address user, address governor, address owner) public {
        registry = new WhitelistRegistry(owner);
        vm.prank(governor);
        ltv.setWhitelistRegistry(address(registry));

        prepareEachFunctionSuccessfulExecution(user);
    }

    function test_checkSlot(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        vm.startPrank(data.governor);
        ltv.setWhitelistRegistry(address(new WhitelistRegistry(data.owner)));

        bool isActivated = ltv.isWhitelistActivated();

        ltv.setIsWhitelistActivated(!isActivated);

        assertEq(ltv.isWhitelistActivated(), !isActivated);
    }

    /// forge-config: default.fuzz.runs = 8
    function test_failIfWhitelistIsActivatedBatch(DefaultTestData memory data, address user) public {
        vm.assume(user != data.feeCollector);

        bytes[] memory calls = whitelistCalls(user);

        for (uint256 i = 0; i < calls.length; i++) {
            failIfWhitelistIsActivated(data, user, calls[i]);
        }
    }

    function failIfWhitelistIsActivated(DefaultTestData memory data, address user, bytes memory call)
        internal
        testWithPredefinedDefaultValues(data)
    {
        prepareWhitelistDepositWithdrawTest(user, data.governor, data.owner);

        vm.prank(data.governor);
        ltv.setIsWhitelistActivated(true);

        vm.prank(user);
        (bool success, bytes memory result) = address(ltv).call(call);

        assertEq(success, false);
        assertEq(result, abi.encodeWithSelector(IAdministrationErrors.ReceiverNotWhitelisted.selector, user));
    }

    /// forge-config: default.fuzz.runs = 8
    function test_passIfWhitelistIsSatisfiedBatch(DefaultTestData memory data, address user) public {
        bytes[] memory calls = whitelistCalls(user);

        for (uint256 i = 0; i < calls.length; i++) {
            passIfWhitelistIsSatisfied(data, user, calls[i]);
        }
    }

    function passIfWhitelistIsSatisfied(DefaultTestData memory data, address user, bytes memory call)
        internal
        testWithPredefinedDefaultValues(data)
    {
        prepareWhitelistDepositWithdrawTest(user, data.governor, data.owner);

        vm.prank(data.governor);
        ltv.setIsWhitelistActivated(true);

        vm.prank(data.owner);
        registry.addAddressToWhitelist(user);

        UserBalance memory initialBalance = getUserBalance(user);
        vm.prank(user);
        (bool success,) = address(ltv).call(call);

        assertEq(success, true);
        checkTokensReceived(initialBalance, getUserBalance(user));
    }

    /// forge-config: default.fuzz.runs = 8
    function test_passIfWhitelistIsNotActivatedBatch(DefaultTestData memory data, address user) public {
        bytes[] memory calls = whitelistCalls(user);

        for (uint256 i = 0; i < calls.length; i++) {
            passIfWhitelistIsNotActivated(data, user, calls[i]);
        }
    }

    function passIfWhitelistIsNotActivated(DefaultTestData memory data, address user, bytes memory call)
        internal
        testWithPredefinedDefaultValues(data)
    {
        prepareWhitelistDepositWithdrawTest(user, data.governor, data.owner);

        vm.prank(data.governor);
        ltv.setIsWhitelistActivated(false);

        UserBalance memory initialBalance = getUserBalance(user);
        vm.prank(user);
        (bool success,) = address(ltv).call(call);

        assertEq(success, true);
        checkTokensReceived(initialBalance, getUserBalance(user));
    }

    function test_failIfWhitelistRegistryIsNotSet(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.startPrank(data.governor);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.WhitelistRegistryNotSet.selector));
        ltv.setIsWhitelistActivated(true);
    }

    function test_failIfNotGovernor(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.governor);

        vm.startPrank(data.governor);
        ltv.setWhitelistRegistry(address(new WhitelistRegistry(data.owner)));

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setIsWhitelistActivated(true);
    }
}
