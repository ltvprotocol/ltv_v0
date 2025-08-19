// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BalancedTest} from "test/utils/BalancedTest.t.sol";
import {ILTV} from "src/interfaces/ILTV.sol";
import {ConstantSlippageProvider} from "src/connectors/slippage_providers/ConstantSlippageProvider.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";
import {WhitelistRegistry} from "src/elements/WhitelistRegistry.sol";
import {IWithGuardian} from "src/timelock/utils/interfaces/IWithGuardian.sol";
import {IWithPayloadsManager} from "src/timelock/utils/interfaces/IWithPayloadsManager.sol";
import {PayloadState} from "src/timelock/TimelockCommon.sol";
import {TimelockCommon} from "src/timelock/TimelockCommon.sol";
import {Timelock} from "src/timelock/Timelock.sol";

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
        actions[0] = abi.encodeCall(dummyLTV.settargetLtv, (6, 10));

        vm.expectRevert(
            abi.encodeWithSelector(IWithPayloadsManager.OnlyPayloadsManagerOrOwnerInvalidCaller.selector, user)
        );
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

        assertEq(dummyLTV.targetLtvDividend(), 6);
        assertEq(dummyLTV.targetLtvDivider(), 10);
    }

    function test_settargetLtv(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        uint16 newValueDividend = 7;
        uint16 newValueDivider = 10;
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);

        vm.startPrank(governor);
        dummyLTV.settargetLtv(newValueDividend, newValueDivider);
        assertEq(dummyLTV.targetLtvDividend(), newValueDividend);
        assertEq(dummyLTV.targetLtvDivider(), newValueDivider);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLTV.settargetLtv(newValueDividend, newValueDivider);

        // Should revert if outside bounds
        vm.startPrank(governor);
        uint16 tooHighValue = dummyLTV.maxSafeLtvDividend() + 1;
        uint16 tooHighDivider = dummyLTV.maxSafeLtvDivider() + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                tooHighValue,
                tooHighDivider,
                dummyLTV.maxSafeLtvDividend(),
                dummyLTV.maxSafeLtvDivider(),
                dummyLTV.minProfitLtvDividend(),
                dummyLTV.minProfitLtvDivider()
            )
        );
        dummyLTV.settargetLtv(tooHighValue, tooHighDivider);

        uint16 tooLowValue = dummyLTV.minProfitLtvDividend() - 1;
        uint16 tooLowDivider = dummyLTV.minProfitLtvDivider();
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                tooLowValue,
                tooLowDivider,
                dummyLTV.maxSafeLtvDividend(),
                dummyLTV.maxSafeLtvDivider(),
                dummyLTV.minProfitLtvDividend(),
                dummyLTV.minProfitLtvDivider()
            )
        );
        dummyLTV.settargetLtv(tooLowValue, tooLowDivider);
    }

    function test_setmaxSafeLtv(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        uint16 newValueDividend = 95;
        uint16 newValueDivider = 100;
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLTV.setmaxSafeLtv(newValueDividend, newValueDivider);
        assertEq(dummyLTV.maxSafeLtvDividend(), newValueDividend);
        assertEq(dummyLTV.maxSafeLtvDivider(), newValueDivider);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLTV.setmaxSafeLtv(newValueDividend, newValueDivider);

        // Should revert if below target
        vm.startPrank(governor);
        uint16 tooLowValue = dummyLTV.targetLtvDividend() - 1;
        uint16 tooLowDivider = dummyLTV.targetLtvDivider();
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                dummyLTV.targetLtvDividend(),
                dummyLTV.targetLtvDivider(),
                tooLowValue,
                tooLowDivider,
                dummyLTV.minProfitLtvDividend(),
                dummyLTV.minProfitLtvDivider()
            )
        );
        dummyLTV.setmaxSafeLtv(tooLowValue, tooLowDivider);

        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.UnexpectedmaxSafeLtv.selector, 2, 1));
        dummyLTV.setmaxSafeLtv(2, 1);
    }

    function test_setminProfitLtv(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        uint16 newValueDividend = 6;
        uint16 newValueDivider = 10;
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLTV.setminProfitLtv(newValueDividend, newValueDivider);
        assertEq(dummyLTV.minProfitLtvDividend(), newValueDividend);
        assertEq(dummyLTV.minProfitLtvDivider(), newValueDivider);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLTV.setminProfitLtv(newValueDividend, newValueDivider);

        // Should revert if above target
        vm.startPrank(governor);
        uint16 tooHighValue = dummyLTV.targetLtvDividend() + 1;
        uint16 tooHighDivider = dummyLTV.targetLtvDivider();
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                dummyLTV.targetLtvDividend(),
                dummyLTV.targetLtvDivider(),
                dummyLTV.maxSafeLtvDividend(),
                dummyLTV.maxSafeLtvDivider(),
                tooHighValue,
                tooHighDivider
            )
        );
        dummyLTV.setminProfitLtv(tooHighValue, tooHighDivider);
    }

    function test_setFeeCollector(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
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

    function test_setMaxTotalAssetsInUnderlying(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
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

    function test_setMaxDeleverageFee(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        uint16 newValueDividend = 1; // 10%
        uint16 newValueDivider = 10;
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLTV.setMaxDeleverageFee(newValueDividend, newValueDivider);
        assertEq(dummyLTV.maxDeleverageFeeDividend(), newValueDividend);
        assertEq(dummyLTV.maxDeleverageFeeDivider(), newValueDivider);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLTV.setMaxDeleverageFee(newValueDividend, newValueDivider);

        // Should revert if dividend > divider
        vm.startPrank(governor);
        uint16 tooHighDividend = 10; // 100/50 = 200% which is invalid
        uint16 tooLowDivider = 5;
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidMaxDeleverageFee.selector, tooHighDividend, tooLowDivider
            )
        );
        dummyLTV.setMaxDeleverageFee(tooHighDividend, tooLowDivider);
    }

    function test_setIsWhitelistActivated(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLTV.setWhitelistRegistry(address(new WhitelistRegistry(owner)));

        dummyLTV.setIsWhitelistActivated(true);
        assertEq(dummyLTV.isWhitelistActivated(), true);

        dummyLTV.setIsWhitelistActivated(false);
        assertEq(dummyLTV.isWhitelistActivated(), false);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLTV.setIsWhitelistActivated(true);
    }

    function test_setWhitelistRegistry(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
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

    function test_setSlippageProvider(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
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

    function test_setMaxGrowthFee(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        uint16 newValueDividend = 1; // 1%
        uint16 newValueDivider = 100;
        address governor = ILTV(address(dummyLTV)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        ILTV(address(dummyLTV)).setMaxGrowthFee(newValueDividend, newValueDivider);
        assertEq(ILTV(address(dummyLTV)).maxGrowthFeeDividend(), newValueDividend);
        assertEq(ILTV(address(dummyLTV)).maxGrowthFeeDivider(), newValueDivider);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ILTV(address(dummyLTV)).setMaxGrowthFee(newValueDividend, newValueDivider);
    }
}
