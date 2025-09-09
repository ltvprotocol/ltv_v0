// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {DefaultTestData} from "test/utils/BaseTest.t.sol";
import {PrepareEachFunctionSuccessfulExecution} from "test/administration/PrepareEachFunctionSuccessfulExecution.sol";
import {IModules} from "src/interfaces/IModules.sol";
import {ModulesState} from "src/structs/state/ModulesState.sol";
import {IBorrowVaultModule} from "src/interfaces/reads/IBorrowVaultModule.sol";
import {ICollateralVaultModule} from "src/interfaces/reads/ICollateralVaultModule.sol";
import {ILowLevelRebalanceModule} from "src/interfaces/reads/ILowLevelRebalanceModule.sol";
import {IAuctionModule} from "src/interfaces/reads/IAuctionModule.sol";
import {IERC20Module} from "src/interfaces/reads/IERC20Module.sol";
import {IInitializeModule} from "src/interfaces/writes/IInitializeModule.sol";
import {IAdministrationModule} from "src/interfaces/reads/IAdministrationModule.sol";
import {BorrowVaultModule} from "src/elements/modules/BorrowVaultModule.sol";
import {CollateralVaultModule} from "src/elements/modules/CollateralVaultModule.sol";
import {LowLevelRebalanceModule} from "src/elements/modules/LowLevelRebalanceModule.sol";
import {AuctionModule} from "src/elements/modules/AuctionModule.sol";
import {AdministrationModule} from "src/elements/modules/AdministrationModule.sol";
import {ERC20Module} from "src/elements/modules/ERC20Module.sol";
import {InitializeModule} from "src/elements/modules/InitializeModule.sol";
import {ModulesProvider} from "src/elements/ModulesProvider.sol";
import {WhitelistRegistry} from "src/elements/WhitelistRegistry.sol";

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
