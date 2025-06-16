// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import "./PrepareEachFunctionSuccessfulExecution.sol";
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

contract SetModulesTest is PrepareEachFunctionSuccessfulExecution {
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

    function verifyCallResultFromTarget(address target, bool success, bytes memory returndata)
        public
        view
        returns (bytes memory)
    {
        if (!success) {
            assembly {
                revert(add(returndata, 32), mload(returndata))
            }
        } else {
            if (returndata.length == 0 && target.code.length == 0) {
                revert IAdministrationErrors.ZeroDataRevert();
            }
        }
        return returndata;
    }

    function functionsCannotBeDisabled(DefaultTestData memory defaultData)
        public
        pure
        returns (bytes[] memory, bytes4[] memory, address[] memory)
    {
        bytes[] memory calls = new bytes[](12);
        bytes4[] memory selectors = new bytes4[](12);
        address[] memory callers = new address[](12);

        calls[0] = abi.encodeCall(ILTV.allowDisableFunctions, (new bytes4[](1), true));
        selectors[0] = ILTV.allowDisableFunctions.selector;
        callers[0] = defaultData.guardian;

        calls[1] = abi.encodeCall(ILTV.deleverageAndWithdraw, (type(uint112).max, 2 * 10 ** 16));
        selectors[1] = ILTV.deleverageAndWithdraw.selector;
        callers[1] = defaultData.emergencyDeleverager;

        calls[2] = abi.encodeCall(ILTV.renounceOwnership, ());
        selectors[2] = ILTV.renounceOwnership.selector;
        callers[2] = defaultData.owner;

        calls[3] = abi.encodeCall(ILTV.setModules, (IModules(address(1))));
        selectors[3] = ILTV.setModules.selector;
        callers[3] = defaultData.owner;

        calls[4] = abi.encodeCall(ILTV.updateGuardian, defaultData.guardian);
        selectors[4] = ILTV.updateGuardian.selector;
        callers[4] = defaultData.owner;

        calls[5] = abi.encodeCall(ILTV.updateGovernor, defaultData.governor);
        selectors[5] = ILTV.updateGovernor.selector;
        callers[5] = defaultData.owner;

        calls[6] = abi.encodeCall(ILTV.updateEmergencyDeleverager, defaultData.emergencyDeleverager);
        selectors[6] = ILTV.updateEmergencyDeleverager.selector;
        callers[6] = defaultData.owner;

        calls[7] = abi.encodeCall(ILTV.setIsDepositDisabled, (false));
        selectors[7] = ILTV.setIsDepositDisabled.selector;
        callers[7] = defaultData.guardian;

        calls[8] = abi.encodeCall(ILTV.setIsWithdrawDisabled, (false));
        selectors[8] = ILTV.setIsWithdrawDisabled.selector;
        callers[8] = defaultData.guardian;

        calls[9] = abi.encodeCall(ILTV.setLendingConnector, address(1));
        selectors[9] = ILTV.setLendingConnector.selector;
        callers[9] = defaultData.owner;

        calls[10] = abi.encodeCall(ILTV.setOracleConnector, address(1));
        selectors[10] = ILTV.setOracleConnector.selector;
        callers[10] = defaultData.owner;

        calls[11] = abi.encodeCall(ILTV.transferOwnership, (defaultData.owner));
        selectors[11] = ILTV.transferOwnership.selector;
        callers[11] = defaultData.owner;

        return (calls, selectors, callers);
    }

    function test_SetModulesChangesApplied(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
        ModulesState memory validModulesState = ModulesState({
            borrowVaultModule: IBorrowVaultModule(address(new BorrowVaultModule())),
            collateralVaultModule: ICollateralVaultModule(address(new CollateralVaultModule())),
            lowLevelRebalanceModule: ILowLevelRebalanceModule(address(new LowLevelRebalanceModule())),
            auctionModule: IAuctionModule(address(new AuctionModule())),
            administrationModule: IAdministrationModule(address(new AdministrationModule())),
            erc20Module: IERC20Module(address(new ERC20Module()))
        });

        ModulesProvider validModulesProvider = new ModulesProvider(validModulesState);
        vm.prank(data.owner);
        ltv.setModules(IModules(address(validModulesProvider)));

        address user = address(0x123);
        vm.prank(user);
        (bool success,) = address(ltv).call{gas: gasleft()}(abi.encodeCall(ILTV.deposit, (1000, user)));
        success;

        ModulesState memory dummyModulesState = ModulesState({
            borrowVaultModule: IBorrowVaultModule(address(0)),
            collateralVaultModule: ICollateralVaultModule(address(0)),
            lowLevelRebalanceModule: ILowLevelRebalanceModule(address(0)),
            auctionModule: IAuctionModule(address(0)),
            administrationModule: IAdministrationModule(address(0)),
            erc20Module: IERC20Module(address(0))
        });

        ModulesProvider dummyModulesProvider = new ModulesProvider(dummyModulesState);
        vm.prank(data.owner);
        ltv.setModules(IModules(address(dummyModulesProvider)));

        UserBalance memory initialBalance = getUserBalance(user);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.ZeroDataRevert.selector));
        ltv.deposit(1000, user);

        UserBalance memory finalBalance = getUserBalance(user);
        assertEq(initialBalance.collateral, finalBalance.collateral);
        assertEq(initialBalance.borrow, finalBalance.borrow);
        assertEq(initialBalance.shares, finalBalance.shares);
    }

    function test_SetCannotZeroModulesProvider(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        ModulesState memory zeroModulesState = ModulesState({
            borrowVaultModule: IBorrowVaultModule(address(0)),
            collateralVaultModule: ICollateralVaultModule(address(0)),
            lowLevelRebalanceModule: ILowLevelRebalanceModule(address(0)),
            auctionModule: IAuctionModule(address(0)),
            administrationModule: IAdministrationModule(address(0)),
            erc20Module: IERC20Module(address(0))
        });
        ModulesProvider zeroModulesProvider = new ModulesProvider(zeroModulesState);
        vm.prank(data.owner);
        ltv.setModules(IModules(address(zeroModulesProvider)));

        address user = address(0x123);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.ZeroDataRevert.selector));
        ltv.deposit(1000, user);
    }

    function test_DummyModulesRevertWithZeroData(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.feeCollector);
        prepareEachFunctionSuccessfulExecution(user);

        ModulesState memory dummyModulesState = ModulesState({
            borrowVaultModule: IBorrowVaultModule(address(0)),
            collateralVaultModule: ICollateralVaultModule(address(0)),
            lowLevelRebalanceModule: ILowLevelRebalanceModule(address(0)),
            auctionModule: IAuctionModule(address(0)),
            administrationModule: IAdministrationModule(address(0)),
            erc20Module: IERC20Module(address(0))
        });
        ModulesProvider dummyModulesProvider = new ModulesProvider(dummyModulesState);
        vm.prank(data.owner);
        ltv.setModules(IModules(address(dummyModulesProvider)));

        bytes[] memory moduleDependentCalls = new bytes[](15);
        uint256 amount = 1000;
        moduleDependentCalls[0] = abi.encodeCall(ILTV.deposit, (amount, user));
        moduleDependentCalls[1] = abi.encodeCall(ILTV.mint, (amount, user));
        moduleDependentCalls[2] = abi.encodeCall(ILTV.redeem, (amount, user, user));
        moduleDependentCalls[3] = abi.encodeCall(ILTV.withdraw, (amount, user, user));
        moduleDependentCalls[4] = abi.encodeCall(ILTV.depositCollateral, (amount, user));
        moduleDependentCalls[5] = abi.encodeCall(ILTV.mintCollateral, (amount, user));
        moduleDependentCalls[6] = abi.encodeCall(ILTV.redeemCollateral, (amount, user, user));
        moduleDependentCalls[7] = abi.encodeCall(ILTV.withdrawCollateral, (amount, user, user));
        moduleDependentCalls[8] = abi.encodeCall(ILTV.executeAuctionBorrow, (int256(amount)));
        moduleDependentCalls[9] = abi.encodeCall(ILTV.executeAuctionCollateral, (int256(amount)));
        moduleDependentCalls[10] = abi.encodeCall(ILTV.executeLowLevelRebalanceBorrow, (int256(amount)));
        moduleDependentCalls[11] = abi.encodeCall(ILTV.executeLowLevelRebalanceBorrowHint, (int256(amount), true));
        moduleDependentCalls[12] = abi.encodeCall(ILTV.executeLowLevelRebalanceCollateral, (int256(amount)));
        moduleDependentCalls[13] = abi.encodeCall(ILTV.executeLowLevelRebalanceCollateralHint, (int256(amount), true));
        moduleDependentCalls[14] = abi.encodeCall(ILTV.executeLowLevelRebalanceShares, (int256(amount)));

        for (uint256 i = 0; i < moduleDependentCalls.length; i++) {
            UserBalance memory initialBalance = getUserBalance(user);

            vm.prank(user);
            vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.ZeroDataRevert.selector));
            (bool success,) = address(ltv).call{gas: gasleft()}(moduleDependentCalls[i]);
            success;

            UserBalance memory finalBalance = getUserBalance(user);
            assertEq(initialBalance.collateral, finalBalance.collateral);
            assertEq(initialBalance.borrow, finalBalance.borrow);
            assertEq(initialBalance.shares, finalBalance.shares);
        }
    }

    function test_OwnableAccountReturnsZeroData(DefaultTestData memory data)
        public
        testWithPredefinedDefaultValues(data)
    {
        address externalAccount = address(0x1234567890123456789012345678901234567890);

        require(externalAccount.code.length == 0);

        ModulesState memory eoaModulesState = ModulesState({
            borrowVaultModule: IBorrowVaultModule(externalAccount),
            collateralVaultModule: ICollateralVaultModule(externalAccount),
            lowLevelRebalanceModule: ILowLevelRebalanceModule(externalAccount),
            auctionModule: IAuctionModule(externalAccount),
            administrationModule: IAdministrationModule(externalAccount),
            erc20Module: IERC20Module(externalAccount)
        });

        ModulesProvider eoaModulesProvider = new ModulesProvider(eoaModulesState);
        vm.prank(data.owner);
        ltv.setModules(IModules(address(eoaModulesProvider)));

        address user = address(0x123);

        vm.prank(user);
        (bool success, bytes memory returnData) = address(ltv).call(abi.encodeCall(ILTV.deposit, (1000, user)));

        try this.verifyCallResultFromTarget(externalAccount, success, returnData) {
            revert();
        } catch (bytes memory reason) {
            assertEq(reason, abi.encodeWithSelector(IAdministrationErrors.ZeroDataRevert.selector));
        }

        vm.prank(user);
        (bool success2, bytes memory returnData2) = address(ltv).call(abi.encodeCall(ILTV.approve, (user, 1000)));

        try this.verifyCallResultFromTarget(externalAccount, success2, returnData2) {
            revert();
        } catch (bytes memory reason) {
            assertEq(reason, abi.encodeWithSelector(IAdministrationErrors.ZeroDataRevert.selector));
        }
    }

    function test_ModulesExecuteSuccessfully(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.feeCollector);
        prepareEachFunctionSuccessfulExecution(user);

        ModulesState memory validModulesState = ModulesState({
            borrowVaultModule: IBorrowVaultModule(address(new BorrowVaultModule())),
            collateralVaultModule: ICollateralVaultModule(address(new CollateralVaultModule())),
            lowLevelRebalanceModule: ILowLevelRebalanceModule(address(new LowLevelRebalanceModule())),
            auctionModule: IAuctionModule(address(new AuctionModule())),
            administrationModule: IAdministrationModule(address(new AdministrationModule())),
            erc20Module: IERC20Module(address(new ERC20Module()))
        });
        ModulesProvider validModulesProvider = new ModulesProvider(validModulesState);
        vm.prank(data.owner);
        ltv.setModules(IModules(address(validModulesProvider)));

        uint256 borrowAssets = ILendingConnector(ltv.getLendingConnector()).getRealBorrowAssets(true);
        deal(address(borrowToken), data.emergencyDeleverager, borrowAssets);
        vm.prank(data.emergencyDeleverager);
        borrowToken.approve(address(ltv), borrowAssets);

        (bytes[] memory calls, bytes4[] memory selectors, address[] memory callers) = functionsCannotBeDisabled(data);

        for (uint256 i = 0; i < calls.length; i++) {
            vm.prank(callers[i]);
            (bool success,) = address(ltv).call(calls[i]);

            if (selectors[i] == ILTV.deleverageAndWithdraw.selector) {
                assertTrue(success || borrowAssets == 0);
            } else if (selectors[i] == ILTV.renounceOwnership.selector) {
                assertTrue(success);
            } else if (
                selectors[i] == ILTV.setModules.selector || selectors[i] == ILTV.updateGuardian.selector
                    || selectors[i] == ILTV.updateGovernor.selector
                    || selectors[i] == ILTV.updateEmergencyDeleverager.selector
                    || selectors[i] == ILTV.setLendingConnector.selector || selectors[i] == ILTV.setOracleConnector.selector
                    || selectors[i] == ILTV.transferOwnership.selector
            ) {
                if (callers[i] == data.owner) {
                    assertFalse(success);
                } else {
                    assertTrue(success);
                }
            } else {
                assertTrue(success);
            }
        }
    }

    function test_ModuleCallSucceedsWithValidModules(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.feeCollector);
        prepareEachFunctionSuccessfulExecution(user);

        ModulesState memory validModulesState = ModulesState({
            borrowVaultModule: IBorrowVaultModule(address(new BorrowVaultModule())),
            collateralVaultModule: ICollateralVaultModule(address(new CollateralVaultModule())),
            lowLevelRebalanceModule: ILowLevelRebalanceModule(address(new LowLevelRebalanceModule())),
            auctionModule: IAuctionModule(address(new AuctionModule())),
            administrationModule: IAdministrationModule(address(new AdministrationModule())),
            erc20Module: IERC20Module(address(new ERC20Module()))
        });
        ModulesProvider validModulesProvider = new ModulesProvider(validModulesState);
        vm.prank(data.owner);
        ltv.setModules(IModules(address(validModulesProvider)));

        bytes[] memory successfulCalls = new bytes[](6);
        successfulCalls[0] = abi.encodeCall(ILTV.deposit, (1000, user));
        successfulCalls[1] = abi.encodeCall(ILTV.mint, (1000, user));
        successfulCalls[2] = abi.encodeCall(ILTV.depositCollateral, (1000, user));
        successfulCalls[3] = abi.encodeCall(ILTV.mintCollateral, (1000, user));
        successfulCalls[4] = abi.encodeCall(ILTV.approve, (user, 1000));
        successfulCalls[5] = abi.encodeCall(ILTV.transfer, (user, 500));

        for (uint256 i = 0; i < successfulCalls.length; i++) {
            vm.prank(user);
            (bool success, bytes memory result) = address(ltv).call(successfulCalls[i]);
            assertTrue(success);
            if (result.length == 0) {
                revert();
            }
        }
    }

    function test_OnlyOwnerCanSetModules(DefaultTestData memory data, address user)
        public
        testWithPredefinedDefaultValues(data)
    {
        vm.assume(user != data.owner);
        ModulesState memory dummyModulesState = ModulesState({
            borrowVaultModule: IBorrowVaultModule(address(0)),
            collateralVaultModule: ICollateralVaultModule(address(0)),
            lowLevelRebalanceModule: ILowLevelRebalanceModule(address(0)),
            auctionModule: IAuctionModule(address(0)),
            administrationModule: IAdministrationModule(address(0)),
            erc20Module: IERC20Module(address(0))
        });
        ModulesProvider dummyModulesProvider = new ModulesProvider(dummyModulesState);
        vm.startPrank(user);
        vm.expectRevert();
        ltv.setModules(IModules(address(dummyModulesProvider)));
    }
}
