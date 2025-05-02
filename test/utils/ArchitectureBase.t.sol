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
        vm.etch(address(dummyLTV), address(ltv).code);

        ltv = LTVWithModules(address(dummyLTV));
        BorrowVaultModule borrowVaultModule = new BorrowVaultModule();
        CollateralVaultModule collateralVaultModule = new CollateralVaultModule();
        AuctionModule auctionModule = new AuctionModule();
        LowLevelRebalanceModule lowLevelRebalanceModule = new LowLevelRebalanceModule();
        ERC20Module erc20Module = new ERC20Module();
        AdministrationModule administrationModule = new AdministrationModule();
        ModulesProvider modules = new ModulesProvider(
            ModulesState({
                borrowVaultsRead: IBorrowVaultRead(address(borrowVaultModule)),
                borrowVaultsWrite: address(borrowVaultModule),
                collateralVaultsRead: ICollateralVaultRead(address(collateralVaultModule)),
                collateralVaultsWrite: address(collateralVaultModule),
                erc20Write: address(erc20Module),
                lowLevelRebalancerRead: ILowLevelRebalanceRead(address(lowLevelRebalanceModule)),
                lowLevelRebalancerWrite: address(lowLevelRebalanceModule),
                auctionRead: IAuctionRead(address(auctionModule)),
                auctionWrite: address(auctionModule),
                administration: IAdministration(address(administrationModule))
            })
        );
        ltv.setModules(modules);
    }
}
