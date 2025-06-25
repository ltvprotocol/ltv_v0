// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import "./PrepareEachFunctionSuccessfulExecution.sol";
import "../../src/events/IAdministrationEvents.sol";
import "../../src/errors/IAdministrationErrors.sol";
import "../../src/elements/ModulesProvider.sol";
import "../../src/structs/state/ModulesState.sol";
import "../../src/interfaces/IModules.sol";
import "../../src/interfaces/reads/IAdministrationModule.sol";
import "../../src/interfaces/reads/IAuctionModule.sol";
import "../../src/interfaces/reads/IERC20Module.sol";
import "../../src/interfaces/reads/ICollateralVaultModule.sol";
import "../../src/interfaces/reads/IBorrowVaultModule.sol";
import "../../src/interfaces/reads/ILowLevelRebalanceModule.sol";
import {AuctionModule} from "../../src/elements/AuctionModule.sol";
import {ERC20Module} from "../../src/elements/ERC20Module.sol";
import {CollateralVaultModule} from "../../src/elements/CollateralVaultModule.sol";
import {BorrowVaultModule} from "../../src/elements/BorrowVaultModule.sol";
import {LowLevelRebalanceModule} from "../../src/elements/LowLevelRebalanceModule.sol";
import {AdministrationModule} from "../../src/elements/AdministrationModule.sol";
import {State} from "../../src/interfaces/ILTV.sol";
import "../../src/elements/WhitelistRegistry.sol";

contract DummyModulesProvider is IModules {
    function borrowVaultModule() external pure override returns (IBorrowVaultModule) {
        return IBorrowVaultModule(address(0));
    }

    function collateralVaultModule() external pure override returns (ICollateralVaultModule) {
        return ICollateralVaultModule(address(0));
    }

    function lowLevelRebalanceModule() external pure override returns (ILowLevelRebalanceModule) {
        return ILowLevelRebalanceModule(address(0));
    }

    function auctionModule() external pure override returns (IAuctionModule) {
        return IAuctionModule(address(0));
    }

    function administrationModule() external pure override returns (IAdministrationModule) {
        return IAdministrationModule(address(0));
    }

    function erc20Module() external pure override returns (IERC20Module) {
        return IERC20Module(address(0));
    }
}

contract SetModulesTest is PrepareEachFunctionSuccessfulExecution, IAdministrationEvents {
    struct UserBalance {
        uint256 collateral;
        uint256 borrow;
        uint256 shares;
    }

    struct CallWithCaller {
        bytes callData;
        address caller;
    }

    function getUserBalance(address user) public view returns (UserBalance memory) {
        return UserBalance({
            collateral: collateralToken.balanceOf(user),
            borrow: borrowToken.balanceOf(user),
            shares: ltv.balanceOf(user)
        });
    }

    function modulesCallsWithCallers(
        address user,
        address owner,
        address governor,
        address guardian,
        address emergencyDeleverager
    ) public pure returns (CallWithCaller[] memory) {
        CallWithCaller[] memory calls = new CallWithCaller[](65);
        uint256 amount = 1000;
        uint256 i = 0;
        bytes4[] memory signatures = new bytes4[](1);
        signatures[0] = ILTV.deposit.selector;
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.approve, (user, amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.transfer, (user, amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.transferFrom, (user, user, amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.convertToAssets, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.convertToShares, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.deposit, (amount, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.mint, (amount, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.redeem, (amount, user, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.withdraw, (amount, user, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.maxDeposit, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.maxMint, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.maxRedeem, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.maxWithdraw, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.previewDeposit, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.previewMint, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.previewRedeem, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.previewWithdraw, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.depositCollateral, (amount, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.mintCollateral, (amount, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.redeemCollateral, (amount, user, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.withdrawCollateral, (amount, user, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.maxDepositCollateral, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.maxMintCollateral, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.maxRedeemCollateral, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.maxWithdrawCollateral, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.previewDepositCollateral, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.previewMintCollateral, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.previewRedeemCollateral, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.previewWithdrawCollateral, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeWithSignature("totalAssetsCollateral()"), user);
        calls[i++] = CallWithCaller(abi.encodeWithSignature("totalAssetsCollateral(bool)", true), user);
        calls[i++] = CallWithCaller(abi.encodeWithSignature("totalAssets()"), user);
        calls[i++] = CallWithCaller(abi.encodeWithSignature("totalAssets(bool)", true), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.executeLowLevelRebalanceBorrow, (int256(amount))), user);
        calls[i++] =
            CallWithCaller(abi.encodeCall(ILTV.executeLowLevelRebalanceBorrowHint, (int256(amount), true)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.executeLowLevelRebalanceCollateral, (int256(amount))), user);
        calls[i++] =
            CallWithCaller(abi.encodeCall(ILTV.executeLowLevelRebalanceCollateralHint, (int256(amount), true)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.executeLowLevelRebalanceShares, (int256(amount))), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.previewLowLevelRebalanceBorrow, (int256(amount))), user);
        calls[i++] =
            CallWithCaller(abi.encodeCall(ILTV.previewLowLevelRebalanceBorrowHint, (int256(amount), true)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.previewLowLevelRebalanceCollateral, (int256(amount))), user);
        calls[i++] =
            CallWithCaller(abi.encodeCall(ILTV.previewLowLevelRebalanceCollateralHint, (int256(amount), true)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.previewLowLevelRebalanceShares, (int256(amount))), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.maxLowLevelRebalanceBorrow, ()), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.maxLowLevelRebalanceCollateral, ()), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.maxLowLevelRebalanceShares, ()), user);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.allowDisableFunctions, (signatures, true)), guardian);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.setIsDepositDisabled, (true)), guardian);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.setIsWithdrawDisabled, (true)), guardian);
        calls[i++] = CallWithCaller(
            abi.encodeCall(ILTV.deleverageAndWithdraw, (type(uint112).max, 2 * 10 ** 16)), emergencyDeleverager
        );
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.setFeeCollector, (user)), governor);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.setIsWhitelistActivated, (true)), governor);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.setMaxDeleverageFee, (amount)), governor);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.setMaxGrowthFee, (amount)), governor);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.setMaxSafeLTV, (uint128(9 * 10 ** 17))), governor);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.setMaxTotalAssetsInUnderlying, (amount)), governor);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.setTargetLTV, (uint128(75 * 10 ** 16))), governor);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.setSlippageProvider, (user)), governor);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.setMinProfitLTV, (uint128(5 * 10 ** 17))), governor);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.setWhitelistRegistry, (user)), governor);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.updateGovernor, (user)), owner);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.setLendingConnector, (user)), owner);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.setOracleConnector, (user)), owner);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.updateGuardian, (user)), owner);
        calls[i++] = CallWithCaller(abi.encodeCall(ILTV.updateEmergencyDeleverager, (user)), owner);
        return calls;
    }

    function test_setAndCheckChangesApplied(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        IModules oldModules = ltv.modules();

        ModulesState memory newModulesState = ModulesState({
            borrowVaultModule: IBorrowVaultModule(address(new BorrowVaultModule())),
            collateralVaultModule: ICollateralVaultModule(address(new CollateralVaultModule())),
            lowLevelRebalanceModule: ILowLevelRebalanceModule(address(new LowLevelRebalanceModule())),
            auctionModule: IAuctionModule(address(new AuctionModule())),
            administrationModule: IAdministrationModule(address(new AdministrationModule())),
            erc20Module: IERC20Module(address(new ERC20Module()))
        });

        IModules newModules = new ModulesProvider(newModulesState);

        vm.expectEmit(true, true, false, false);
        emit ModulesUpdated(address(oldModules), address(newModules));

        vm.prank(data.owner);
        ltv.setModules(newModules);

        IModules updatedModules = ltv.modules();
        assertEq(address(updatedModules), address(newModules));
        assertNotEq(address(updatedModules), address(oldModules));

        assertNotEq(address(oldModules.administrationModule()), address(newModules.administrationModule()));
        assertNotEq(address(oldModules.auctionModule()), address(newModules.auctionModule()));
        assertNotEq(address(oldModules.erc20Module()), address(newModules.erc20Module()));
        assertNotEq(address(oldModules.collateralVaultModule()), address(newModules.collateralVaultModule()));
        assertNotEq(address(oldModules.borrowVaultModule()), address(newModules.borrowVaultModule()));
        assertNotEq(address(oldModules.lowLevelRebalanceModule()), address(newModules.lowLevelRebalanceModule()));

        assertEq(address(updatedModules.administrationModule()), address(newModules.administrationModule()));
        assertEq(address(updatedModules.auctionModule()), address(newModules.auctionModule()));
        assertEq(address(updatedModules.erc20Module()), address(newModules.erc20Module()));
        assertEq(address(updatedModules.collateralVaultModule()), address(newModules.collateralVaultModule()));
        assertEq(address(updatedModules.borrowVaultModule()), address(newModules.borrowVaultModule()));
        assertEq(address(updatedModules.lowLevelRebalanceModule()), address(newModules.lowLevelRebalanceModule()));
    }

    function test_failIfZeroModulesProvider(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        vm.expectRevert(IAdministrationErrors.EOADelegateCall.selector);
        vm.prank(data.owner);
        ltv.setModules(IModules(address(0)));
    }

    function test_dummyModulesProviderRevertsWithZeroData(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        DummyModulesProvider dummyModules = new DummyModulesProvider();

        vm.prank(data.owner);
        ltv.setModules(IModules(address(dummyModules)));

        CallWithCaller[] memory calls =
            modulesCallsWithCallers(data.owner, data.owner, data.governor, data.guardian, data.emergencyDeleverager);

        bytes memory expectedEOAError = abi.encodeWithSelector(IAdministrationErrors.EOADelegateCall.selector);
        bytes memory expectedNonContractError =
            abi.encode(string.concat("call to non-contract address ", vm.toString(address(0))));

        for (uint256 i = 0; i < calls.length; i++) {
            vm.prank(calls[i].caller);
            (bool success, bytes memory returnData) = address(ltv).call(calls[i].callData);

            assertFalse(success);

            bool expectedError =
                equalBytes(returnData, expectedEOAError) || equalBytes(returnData, expectedNonContractError);

            assertTrue(expectedError);
        }
    }

    function equalBytes(bytes memory a, bytes memory b) internal pure returns (bool) {
        if (a.length != b.length) {
            return false;
        }
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }

    function test_everyFunctionExecutesWithValidModules(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        ModulesState memory newModulesState = ModulesState({
            borrowVaultModule: IBorrowVaultModule(address(new BorrowVaultModule())),
            collateralVaultModule: ICollateralVaultModule(address(new CollateralVaultModule())),
            lowLevelRebalanceModule: ILowLevelRebalanceModule(address(new LowLevelRebalanceModule())),
            auctionModule: IAuctionModule(address(new AuctionModule())),
            administrationModule: IAdministrationModule(address(new AdministrationModule())),
            erc20Module: IERC20Module(address(new ERC20Module()))
        });
        vm.assume(data.owner != address(0));
        vm.assume(data.guardian != address(0));
        vm.assume(data.governor != address(0));
        vm.assume(data.emergencyDeleverager != address(0));
        vm.assume(data.feeCollector != address(0));
        IModules newModules = new ModulesProvider(newModulesState);

        vm.prank(data.owner);
        ltv.setModules(newModules);

        assertEq(address(ltv.modules()), address(newModules));

        address testUser = makeAddr("testUser");

        prepareEachFunctionSuccessfulExecution(testUser);

        deal(address(borrowToken), data.emergencyDeleverager, type(uint112).max);
        deal(address(collateralToken), data.emergencyDeleverager, type(uint112).max);

        vm.startPrank(data.emergencyDeleverager);
        borrowToken.approve(address(ltv), type(uint112).max);
        collateralToken.approve(address(ltv), type(uint112).max);
        vm.stopPrank();

        WhitelistRegistry registry = new WhitelistRegistry(data.owner);
        vm.prank(data.governor);
        ltv.setWhitelistRegistry(address(registry));

        CallWithCaller[] memory calls =
            modulesCallsWithCallers(testUser, data.owner, data.governor, data.guardian, data.emergencyDeleverager);

        for (uint256 i = 0; i < calls.length; i++) {
            vm.prank(calls[i].caller);
            (bool success,) = address(ltv).call(calls[i].callData);

            require(success);
        }
    }

    function test_failIfNotOwner(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.owner);

        IModules currentModules = ltv.modules();

        vm.prank(user);
        vm.expectRevert();
        ltv.setModules(currentModules);
    }
}
