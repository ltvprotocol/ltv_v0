// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {IERC4626Collateral} from "test/interfaces/IERC4626Collateral.sol";
import {DefaultTestData} from "test/utils/BaseTest.t.sol";
import {PrepareEachFunctionSuccessfulExecution} from "test/administration/PrepareEachFunctionSuccessfulExecution.sol";
import {IModules} from "src/interfaces/IModules.sol";
import {ModulesState} from "src/structs/state/common/ModulesState.sol";
import {IBorrowVaultModule} from "src/interfaces/reads/IBorrowVaultModule.sol";
import {ICollateralVaultModule} from "src/interfaces/reads/ICollateralVaultModule.sol";
import {ILowLevelRebalanceModule} from "src/interfaces/reads/ILowLevelRebalanceModule.sol";
import {IAuctionModule} from "src/interfaces/reads/IAuctionModule.sol";
import {IERC20Module} from "src/interfaces/reads/IERC20Module.sol";
import {IAdministrationModule} from "src/interfaces/reads/IAdministrationModule.sol";
import {IInitializeModule} from "src/interfaces/writes/IInitializeModule.sol";
import {BorrowVaultModule} from "src/elements/modules/BorrowVaultModule.sol";
import {CollateralVaultModule} from "src/elements/modules/CollateralVaultModule.sol";
import {LowLevelRebalanceModule} from "src/elements/modules/LowLevelRebalanceModule.sol";
import {AuctionModule} from "src/elements/modules/AuctionModule.sol";
import {AdministrationModule} from "src/elements/modules/AdministrationModule.sol";
import {ERC20Module} from "src/elements/modules/ERC20Module.sol";
import {InitializeModule} from "src/elements/modules/InitializeModule.sol";
import {ModulesProvider} from "src/elements/ModulesProvider.sol";
import {WhitelistRegistry} from "src/elements/WhitelistRegistry.sol";

contract ERC4626CompatibilityTest is PrepareEachFunctionSuccessfulExecution {
    struct CallWithCaller {
        bytes callData;
        address caller;
    }

    address testUser = makeAddr("testUser");

    function erc4626CallsWithCaller(address user) public pure returns (CallWithCaller[] memory) {
        CallWithCaller[] memory calls = new CallWithCaller[](32);
        uint256 amount = 100;
        uint256 i = 0;

        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.asset, ()), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.totalAssets, ()), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.convertToShares, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.convertToAssets, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.maxDeposit, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.previewDeposit, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.deposit, (amount, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.maxMint, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.previewMint, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.mint, (amount, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.maxWithdraw, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.previewWithdraw, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.withdraw, (amount, user, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.maxRedeem, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.previewRedeem, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626.redeem, (amount, user, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.assetCollateral, ()), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.totalAssetsCollateral, ()), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.convertToSharesCollateral, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.convertToAssetsCollateral, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.maxDepositCollateral, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.previewDepositCollateral, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.depositCollateral, (amount, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.maxMintCollateral, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.previewMintCollateral, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.mintCollateral, (amount, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.maxWithdrawCollateral, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.previewWithdrawCollateral, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.withdrawCollateral, (amount, user, user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.maxRedeemCollateral, (user)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.previewRedeemCollateral, (amount)), user);
        calls[i++] = CallWithCaller(abi.encodeCall(IERC4626Collateral.redeemCollateral, (amount, user, user)), user);

        return calls;
    }

    function initExecutionEnvironment(DefaultTestData memory data) public {
        ModulesState memory newModulesState = ModulesState({
            borrowVaultModule: IBorrowVaultModule(address(new BorrowVaultModule())),
            collateralVaultModule: ICollateralVaultModule(address(new CollateralVaultModule())),
            lowLevelRebalanceModule: ILowLevelRebalanceModule(address(new LowLevelRebalanceModule())),
            auctionModule: IAuctionModule(address(new AuctionModule())),
            administrationModule: IAdministrationModule(address(new AdministrationModule())),
            erc20Module: IERC20Module(address(new ERC20Module())),
            initializeModule: IInitializeModule(address(new InitializeModule()))
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

        CallWithCaller[] memory calls = erc4626CallsWithCaller(testUser);

        for (uint256 i = 0; i < calls.length; i++) {
            vm.prank(calls[i].caller);
            (bool success,) = address(ltv).call(calls[i].callData);

            require(success);
        }
    }

    function test_depositExecutesAndEmitsEvent(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        initExecutionEnvironment(data);

        vm.expectEmit(false, false, false, false);
        emit IERC4626.Deposit(address(0), address(0), 0, 0);

        vm.prank(testUser);
        ltv.deposit(10000, testUser);
    }

    function test_withdrawExecutesAndEmitsEvent(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        initExecutionEnvironment(data);

        vm.expectEmit(false, false, false, false);
        emit IERC4626.Withdraw(address(0), address(0), address(0), 0, 0);

        vm.prank(testUser);
        ltv.withdraw(10000, testUser, testUser);
    }

    function test_mintExecutesAndEmitsEvent(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        initExecutionEnvironment(data);

        vm.expectEmit(false, false, false, false);
        emit IERC4626.Deposit(address(0), address(0), 0, 0);

        vm.prank(testUser);
        ltv.mint(10000, testUser);
    }

    function test_redeemExecutesAndEmitsEvent(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        initExecutionEnvironment(data);

        vm.expectEmit(false, false, false, false);
        emit IERC4626.Withdraw(address(0), address(0), address(0), 0, 0);

        vm.prank(testUser);
        ltv.redeem(10000, testUser, testUser);
    }

    function test_depositCollateralExecutesAndEmitsEvent(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        initExecutionEnvironment(data);

        vm.expectEmit(false, false, false, false);
        emit IERC4626Collateral.DepositCollateral(address(0), address(0), 0, 0);

        vm.prank(testUser);
        ltv.depositCollateral(10000, testUser);
    }

    function test_withdrawCollateralExecutesAndEmitsEvent(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        initExecutionEnvironment(data);

        vm.expectEmit(false, false, false, false);
        emit IERC4626Collateral.WithdrawCollateral(address(0), address(0), address(0), 0, 0);

        vm.prank(testUser);
        ltv.withdrawCollateral(10000, testUser, testUser);
    }

    function test_mintCollateralExecutesAndEmitsEvent(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        initExecutionEnvironment(data);

        vm.expectEmit(false, false, false, false);
        emit IERC4626Collateral.DepositCollateral(address(0), address(0), 0, 0);

        vm.prank(testUser);
        ltv.mintCollateral(10000, testUser);
    }

    function test_redeemCollateralExecutesAndEmitsEvent(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        initExecutionEnvironment(data);

        vm.expectEmit(false, false, false, false);
        emit IERC4626Collateral.WithdrawCollateral(address(0), address(0), address(0), 0, 0);

        vm.prank(testUser);
        ltv.redeemCollateral(10000, testUser, testUser);
    }
}
