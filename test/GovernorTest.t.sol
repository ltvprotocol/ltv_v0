// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../src/elements/WhitelistRegistry.sol';
import './utils/BalancedTest.t.sol';
import '../src/timelock/utils/interfaces/IWithGuardian.sol';

contract GovernorTest is BalancedTest {
    function test_governor(
        address ltvOwner,
        address user,
        address owner,
        address payloadsManager,
        address guardian,
        uint32 delay
    ) public initializeBalancedTest(ltvOwner, user, 10 ** 17, 0, 0, 0) {
        vm.assume(ltvOwner != address(0));
        vm.assume(owner != address(0));
        vm.assume(user != payloadsManager);
        vm.assume(delay != 0);
        vm.assume(user != owner);
        vm.assume(user != guardian);

        vm.stopPrank();
        vm.startPrank(ltvOwner);

        Timelock controller = new Timelock(owner, guardian, payloadsManager, delay);

        dummyLTV.updateGovernor(address(controller));

        vm.startPrank(user);

        bytes[] memory actions = new bytes[](1);
        actions[0] = abi.encodeCall(dummyLTV.setTargetLTV, (6 * 10 ** 17));

        vm.expectRevert(abi.encodeWithSelector(IWithPayloadsManager.OnlyPayloadsManagerOrOwnerInvalidCaller.selector, user));
        controller.createPayload(address(dummyLTV), new bytes[](0));

        vm.startPrank(payloadsManager);
        uint40 payloadId = controller.createPayload(address(dummyLTV), actions);

        vm.startPrank(user);
        vm.expectPartialRevert(TimelockCommon.DelayNotPassed.selector);
        controller.executePayload(payloadId);

        vm.expectPartialRevert(IWithGuardian.OnlyGuardianOrOwnerInvalidCaller.selector);
        controller.cancelPayload(payloadId);

        vm.startPrank(guardian);
        controller.cancelPayload(payloadId);
        require(controller.getPayload(payloadId).state == PayloadState.Cancelled);

        vm.startPrank(payloadsManager);
        payloadId = controller.createPayload(address(dummyLTV), actions);
        vm.warp(block.timestamp + delay + 1);

        vm.startPrank(user);
        controller.executePayload(payloadId);

        require(dummyLTV.targetLTV() == 6 * 10 ** 17);
    }

    function test_setTargetLTV(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        uint128 newValue = 7 * 10 ** 17;
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);

        vm.startPrank(governor);
        dummyLTV.setTargetLTV(newValue);
        assertEq(dummyLTV.targetLTV(), newValue);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLTV.setTargetLTV(newValue);

        // Should revert if outside bounds
        vm.startPrank(governor);
        uint128 tooHighValue = dummyLTV.maxSafeLTV() + 1;
        vm.expectRevert(
            abi.encodeWithSelector(IAdministrationErrors.InvalidLTVSet.selector, tooHighValue, dummyLTV.maxSafeLTV(), dummyLTV.minProfitLTV())
        );
        dummyLTV.setTargetLTV(tooHighValue);

        uint128 tooLowValue = dummyLTV.minProfitLTV() - 1;
        vm.expectRevert(
            abi.encodeWithSelector(IAdministrationErrors.InvalidLTVSet.selector, tooLowValue, dummyLTV.maxSafeLTV(), dummyLTV.minProfitLTV())
        );
        dummyLTV.setTargetLTV(tooLowValue);
    }

    function test_setMaxSafeLTV(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        uint128 newValue = 95 * 10 ** 16;
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLTV.setMaxSafeLTV(newValue);
        assertEq(dummyLTV.maxSafeLTV(), newValue);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLTV.setMaxSafeLTV(newValue);

        // Should revert if below target
        vm.startPrank(governor);
        uint128 tooLowValue = dummyLTV.targetLTV() - 1;
        vm.expectRevert(
            abi.encodeWithSelector(IAdministrationErrors.InvalidLTVSet.selector, dummyLTV.targetLTV(), tooLowValue, dummyLTV.minProfitLTV())
        );
        dummyLTV.setMaxSafeLTV(tooLowValue);

        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.UnexpectedMaxSafeLTV.selector, Constants.LTV_DIVIDER));
        dummyLTV.setMaxSafeLTV(uint128(Constants.LTV_DIVIDER));
    }

    function test_setMinProfitLTV(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        uint128 newValue = 6 * 10 ** 17;
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLTV.setMinProfitLTV(newValue);
        assertEq(dummyLTV.minProfitLTV(), newValue);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLTV.setMinProfitLTV(newValue);

        // Should revert if above target
        vm.startPrank(governor);
        uint128 tooHighValue = dummyLTV.targetLTV() + 1;
        vm.expectRevert(
            abi.encodeWithSelector(IAdministrationErrors.InvalidLTVSet.selector, dummyLTV.targetLTV(), dummyLTV.maxSafeLTV(), tooHighValue)
        );
        dummyLTV.setMinProfitLTV(tooHighValue);
    }

    function test_setFeeCollector(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        address newCollector = address(0x1234);
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLTV.setFeeCollector(newCollector);
        assertEq(dummyLTV.feeCollector(), newCollector);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLTV.setFeeCollector(newCollector);
    }

    function test_setMaxTotalAssetsInUnderlying(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        uint256 newValue = 1000000 * 10 ** 18;
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLTV.setMaxTotalAssetsInUnderlying(newValue);
        assertEq(dummyLTV.maxTotalAssetsInUnderlying(), newValue);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLTV.setMaxTotalAssetsInUnderlying(newValue);
    }

    function test_setMaxDeleverageFee(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        uint256 newValue = 1 * 10 ** 17; // 10%
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLTV.setMaxDeleverageFee(newValue);
        assertEq(dummyLTV.maxDeleverageFee(), newValue);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLTV.setMaxDeleverageFee(newValue);

        // Should revert if too high
        vm.startPrank(governor);
        uint256 tooHighValue = 10 ** 18; // 100%
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.InvalidMaxDeleverageFee.selector, tooHighValue));
        dummyLTV.setMaxDeleverageFee(tooHighValue);
    }

    function test_setIsWhitelistActivated(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLTV.setIsWhitelistActivated(true);
        assertEq(dummyLTV.isWhitelistActivated(), true);

        dummyLTV.setIsWhitelistActivated(false);
        assertEq(dummyLTV.isWhitelistActivated(), false);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLTV.setIsWhitelistActivated(true);
    }

    function test_setWhitelistRegistry(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        WhitelistRegistry registry = new WhitelistRegistry(owner);

        dummyLTV.setWhitelistRegistry(address(registry));
        assertEq(address(dummyLTV.whitelistRegistry()), address(registry));

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLTV.setWhitelistRegistry(address(0));
    }

    function test_setSlippageProvider(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        ConstantSlippageProvider provider = new ConstantSlippageProvider(0, 0, owner);

        dummyLTV.setSlippageProvider(address(provider));
        assertEq(address(dummyLTV.slippageProvider()), address(provider));

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLTV.setSlippageProvider(address(0));
    }

    function test_setMaxGrowthFee(address owner, address user) public initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0) {
        uint256 newValue = 1 * 10 ** 16; // 1%
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        ILTV(address(dummyLTV)).setMaxGrowthFee(newValue);
        assertEq(ILTV(address(dummyLTV)).maxGrowthFee(), newValue);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ILTV(address(dummyLTV)).setMaxGrowthFee(newValue);
    }
}
