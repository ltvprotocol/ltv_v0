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

        dummyLtv.updateGovernor(address(controller));

        vm.startPrank(user);

        bytes[] memory actions = new bytes[](1);
        actions[0] = abi.encodeCall(dummyLtv.setTargetLtv, (6, 10));

        vm.expectRevert(
            abi.encodeWithSelector(IWithPayloadsManager.OnlyPayloadsManagerOrOwnerInvalidCaller.selector, user)
        );
        controller.createPayload(address(dummyLtv), new bytes[](0));

        vm.startPrank(payloadsManager);
        uint40 payloadId = controller.createPayload(address(dummyLtv), actions);

        vm.startPrank(user);
        vm.expectPartialRevert(TimelockCommon.DelayNotPassed.selector);
        controller.executePayload(payloadId);

        vm.expectPartialRevert(IWithGuardian.OnlyGuardianOrOwnerInvalidCaller.selector);
        controller.cancelPayload(payloadId);

        vm.startPrank(guardian);
        controller.cancelPayload(payloadId);
        require(controller.getPayload(payloadId).state == PayloadState.Cancelled);

        vm.startPrank(payloadsManager);
        payloadId = controller.createPayload(address(dummyLtv), actions);
        vm.warp(block.timestamp + delay + 1);

        vm.startPrank(user);
        controller.executePayload(payloadId);

        assertEq(dummyLtv.targetLtvDividend(), 6);
        assertEq(dummyLtv.targetLtvDivider(), 10);
    }

    function test_setTargetLtv(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        uint16 newValueDividend = 7;
        uint16 newValueDivider = 10;
        address governor = ILTV(address(dummyLtv)).governor();
        vm.assume(user != governor);

        vm.startPrank(governor);
        dummyLtv.setTargetLtv(newValueDividend, newValueDivider);
        assertEq(dummyLtv.targetLtvDividend(), newValueDividend);
        assertEq(dummyLtv.targetLtvDivider(), newValueDivider);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLtv.setTargetLtv(newValueDividend, newValueDivider);

        // Should revert if outside bounds
        vm.startPrank(governor);
        uint16 tooHighValue = dummyLtv.maxSafeLtvDividend() + 1;
        uint16 tooHighDivider = dummyLtv.maxSafeLtvDivider() + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                tooHighValue,
                tooHighDivider,
                dummyLtv.maxSafeLtvDividend(),
                dummyLtv.maxSafeLtvDivider(),
                dummyLtv.minProfitLtvDividend(),
                dummyLtv.minProfitLtvDivider()
            )
        );
        dummyLtv.setTargetLtv(tooHighValue, tooHighDivider);

        uint16 tooLowValue = dummyLtv.minProfitLtvDividend() - 1;
        uint16 tooLowDivider = dummyLtv.minProfitLtvDivider();
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                tooLowValue,
                tooLowDivider,
                dummyLtv.maxSafeLtvDividend(),
                dummyLtv.maxSafeLtvDivider(),
                dummyLtv.minProfitLtvDividend(),
                dummyLtv.minProfitLtvDivider()
            )
        );
        dummyLtv.setTargetLtv(tooLowValue, tooLowDivider);
    }

    function test_setMaxSafeLtv(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        uint16 newValueDividend = 95;
        uint16 newValueDivider = 100;
        address governor = ILTV(address(dummyLtv)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLtv.setMaxSafeLtv(newValueDividend, newValueDivider);
        assertEq(dummyLtv.maxSafeLtvDividend(), newValueDividend);
        assertEq(dummyLtv.maxSafeLtvDivider(), newValueDivider);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLtv.setMaxSafeLtv(newValueDividend, newValueDivider);

        // Should revert if below target
        vm.startPrank(governor);
        uint16 tooLowValue = dummyLtv.targetLtvDividend() - 1;
        uint16 tooLowDivider = dummyLtv.targetLtvDivider();
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                dummyLtv.targetLtvDividend(),
                dummyLtv.targetLtvDivider(),
                tooLowValue,
                tooLowDivider,
                dummyLtv.minProfitLtvDividend(),
                dummyLtv.minProfitLtvDivider()
            )
        );
        dummyLtv.setMaxSafeLtv(tooLowValue, tooLowDivider);

        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.UnexpectedmaxSafeLtv.selector, 2, 1));
        dummyLtv.setMaxSafeLtv(2, 1);
    }

    function test_setMinProfitLtv(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        uint16 newValueDividend = 6;
        uint16 newValueDivider = 10;
        address governor = ILTV(address(dummyLtv)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLtv.setMinProfitLtv(newValueDividend, newValueDivider);
        assertEq(dummyLtv.minProfitLtvDividend(), newValueDividend);
        assertEq(dummyLtv.minProfitLtvDivider(), newValueDivider);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLtv.setMinProfitLtv(newValueDividend, newValueDivider);

        // Should revert if above target
        vm.startPrank(governor);
        uint16 tooHighValue = dummyLtv.targetLtvDividend() + 1;
        uint16 tooHighDivider = dummyLtv.targetLtvDivider();
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidLTVSet.selector,
                dummyLtv.targetLtvDividend(),
                dummyLtv.targetLtvDivider(),
                dummyLtv.maxSafeLtvDividend(),
                dummyLtv.maxSafeLtvDivider(),
                tooHighValue,
                tooHighDivider
            )
        );
        dummyLtv.setMinProfitLtv(tooHighValue, tooHighDivider);
    }

    function test_setFeeCollector(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        address newCollector = address(0x1234);
        address governor = ILTV(address(dummyLtv)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLtv.setFeeCollector(newCollector);
        assertEq(dummyLtv.feeCollector(), newCollector);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLtv.setFeeCollector(newCollector);
    }

    function test_setMaxTotalAssetsInUnderlying(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        uint256 newValue = 1000000 * 10 ** 18;
        address governor = ILTV(address(dummyLtv)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLtv.setMaxTotalAssetsInUnderlying(newValue);
        assertEq(dummyLtv.maxTotalAssetsInUnderlying(), newValue);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLtv.setMaxTotalAssetsInUnderlying(newValue);
    }

    function test_setMaxDeleverageFee(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        uint16 newValueDividend = 1; // 10%
        uint16 newValueDivider = 10;
        address governor = ILTV(address(dummyLtv)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLtv.setMaxDeleverageFee(newValueDividend, newValueDivider);
        assertEq(dummyLtv.maxDeleverageFeeDividend(), newValueDividend);
        assertEq(dummyLtv.maxDeleverageFeeDivider(), newValueDivider);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLtv.setMaxDeleverageFee(newValueDividend, newValueDivider);

        // Should revert if dividend > divider
        vm.startPrank(governor);
        uint16 tooHighDividend = 10; // 100/50 = 200% which is invalid
        uint16 tooLowDivider = 5;
        vm.expectRevert(
            abi.encodeWithSelector(
                IAdministrationErrors.InvalidMaxDeleverageFee.selector, tooHighDividend, tooLowDivider
            )
        );
        dummyLtv.setMaxDeleverageFee(tooHighDividend, tooLowDivider);
    }

    function test_setIsWhitelistActivated(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        address governor = ILTV(address(dummyLtv)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        dummyLtv.setWhitelistRegistry(address(new WhitelistRegistry(owner)));

        dummyLtv.setIsWhitelistActivated(true);
        assertEq(dummyLtv.isWhitelistActivated(), true);

        dummyLtv.setIsWhitelistActivated(false);
        assertEq(dummyLtv.isWhitelistActivated(), false);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLtv.setIsWhitelistActivated(true);
    }

    function test_setWhitelistRegistry(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        address governor = ILTV(address(dummyLtv)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        WhitelistRegistry registry = new WhitelistRegistry(owner);

        dummyLtv.setWhitelistRegistry(address(registry));
        assertEq(address(dummyLtv.whitelistRegistry()), address(registry));

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLtv.setWhitelistRegistry(address(0));
    }

    function test_setSlippageProvider(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        address governor = ILTV(address(dummyLtv)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        ConstantSlippageProvider provider = new ConstantSlippageProvider(0, 0, owner);

        dummyLtv.setSlippageProvider(address(provider));
        assertEq(address(dummyLtv.slippageProvider()), address(provider));

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        dummyLtv.setSlippageProvider(address(0));
    }

    function test_setMaxGrowthFee(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        uint16 newValueDividend = 1; // 1%
        uint16 newValueDivider = 100;
        address governor = ILTV(address(dummyLtv)).governor();
        vm.assume(user != governor);
        vm.startPrank(governor);
        ILTV(address(dummyLtv)).setMaxGrowthFee(newValueDividend, newValueDivider);
        assertEq(ILTV(address(dummyLtv)).maxGrowthFeeDividend(), newValueDividend);
        assertEq(ILTV(address(dummyLtv)).maxGrowthFeeDivider(), newValueDivider);

        // Should revert if not governor
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ILTV(address(dummyLtv)).setMaxGrowthFee(newValueDividend, newValueDivider);
    }
}
