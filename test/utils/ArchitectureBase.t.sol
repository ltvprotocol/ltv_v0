// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'forge-std/Test.sol';
import {DummyLTV} from './DummyLTV.t.sol';

import 'src/elements/BorrowVaultModule.sol';
import 'src/elements/CollateralVaultModule.sol';
import 'src/elements/AuctionModule.sol';
import 'src/elements/LowLevelRebalanceModule.sol';
import 'src/elements/ModulesProvider.sol';
import 'src/elements/ERC20Module.sol';
import 'src/elements/AdministrationModule.sol';
import 'src/elements/InititializeModule.sol';

import './LTVWithModules.sol';

contract ArchitectureBase is Test {
    DummyLTV dummyLTV;

    function needToReplaceImplementation() internal pure virtual returns (bool) {
        return false;
    }

    function replaceImplementation() internal {
        if (!needToReplaceImplementation()) {
            return;
        }

        LTVWithModules ltv = new LTVWithModules();
        console.log(dummyLTV.owner());
        vm.etch(address(dummyLTV), address(ltv).code);

        ltv = LTVWithModules(address(dummyLTV));
        BorrowVaultModule borrowVaultModule = new BorrowVaultModule();
        CollateralVaultModule collateralVaultModule = new CollateralVaultModule();
        AuctionModule auctionModule = new AuctionModule();
        LowLevelRebalanceModule lowLevelRebalanceModule = new LowLevelRebalanceModule();
        ERC20Module erc20Module = new ERC20Module();
        AdministrationModule administrationModule = new AdministrationModule();
        InitializeModule initializeModule = new InitializeModule();
        ModulesProvider modules = new ModulesProvider(
            ModulesState({
                borrowVault: IBorrowVault(address(borrowVaultModule)),
                collateralVault: ICollateralVault(address(collateralVaultModule)),
                lowLevelRebalance: ILowLevelRebalance(address(lowLevelRebalanceModule)),
                auction: IAuction(address(auctionModule)),
                administration: IAdministration(address(administrationModule)),
                erc20: IERC20Read(address(erc20Module)),
                initializeWrite: address(initializeModule)
            })
        );
        ltv.setModules(modules);

        vm.startPrank(ltv.owner());
        ltv.updateGovernor(address(123));
        ltv.updateGuardian(address(132));
        ltv.updateEmergencyDeleverager(address(213));
        vm.stopPrank();
    }
}
