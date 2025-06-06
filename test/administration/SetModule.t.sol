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

    function modulesCalls(address user) public pure returns (bytes[] memory) {
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

    function prepareModulesTest(address user) public {
        prepareEachFunctionSuccessfulExecution(user);
    }

    function test_setModulesChangesApplied(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
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

        address user = address(0x123);

        UserBalance memory initialBalance = getUserBalance(user);

        bytes memory call = abi.encodeCall(ILTV.deposit, (1000, user));
        vm.prank(user);
        (bool success,) = address(ltv).call(call);

        assertEq(success, true);

        UserBalance memory finalBalance = getUserBalance(user);
        assertEq(initialBalance.collateral, finalBalance.collateral);
        assertEq(initialBalance.borrow, finalBalance.borrow);
        assertEq(initialBalance.shares, finalBalance.shares);
    }

    function test_nonZeroModules(DefaultTestData memory data) public testWithPredefinedDefaultValues(data) {
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
    }

    /// forge-config: default.fuzz.runs = 10
    function test_dummyModulesRevertWithZeroData(DefaultTestData memory data, address user) public {
        vm.assume(user != data.feeCollector);

        bytes[] memory calls = modulesCalls(user);

        for (uint256 i = 0; i < calls.length; i++) {
            checkDummyModulesRevert(data, user, calls[i]);
        }
    }

    function checkDummyModulesRevert(DefaultTestData memory data, address user, bytes memory call)
        internal
        testWithPredefinedDefaultValues(data)
    {
        prepareModulesTest(user);

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
        (bool success,) = address(ltv).call(call);

        assertEq(success, true);

        UserBalance memory finalBalance = getUserBalance(user);

        assertEq(initialBalance.collateral, finalBalance.collateral);
        assertEq(initialBalance.borrow, finalBalance.borrow);
        assertEq(initialBalance.shares, finalBalance.shares);
    }

    function test_onlyOwnerCanSetModules(DefaultTestData memory data, address user)
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
