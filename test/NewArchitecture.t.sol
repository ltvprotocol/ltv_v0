// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import './utils/LTVWithModules.sol';
import 'src/elements/BorrowVaultModule.sol';
import 'src/elements/CollateralVaultModule.sol';
import 'src/elements/ModulesProvider.sol';
import {GeneratedTests} from './Generated.t.sol';
import {DummyLTVTest} from './DummyLTV.t.sol';

contract NewArchitectureGeneratedTest is GeneratedTests {
    function replaceImplementation() internal override {
        LTVWithModules ltv = new LTVWithModules();
        vm.etch(address(dummyLTV), address(ltv).code);

        ltv = LTVWithModules(address(dummyLTV));
        BorrowVaultModule borrowVaultModule = new BorrowVaultModule();
        CollateralVaultModule collateralVaultModule = new CollateralVaultModule();

        ModulesProvider modules = new ModulesProvider(
            ModulesState({
                borrowVaultsRead: IBorrowVaultRead(address(borrowVaultModule)),
                borrowVaultsWrite: address(borrowVaultModule),
                collateralVaultsRead: ICollateralVaultRead(address(collateralVaultModule)),
                collateralVaultsWrite: address(collateralVaultModule),
                erc20Read: IERC20Read(address(0)),
                erc20Write: address(0),
                lowLevelRebalancerRead: ILowLevelRebalanceRead(address(0)),
                lowLevelRebalancerWrite: address(0),
                auctionRead: IAuctionRead(address(0)),
                auctionWrite: address(0)
            })
        );
        ltv.setModules(modules);
    }
}

contract NewArchitectureTest is DummyLTVTest {
    function replaceImplementation() internal override {
        LTVWithModules ltv = new LTVWithModules();
        vm.etch(address(dummyLTV), address(ltv).code);

        ltv = LTVWithModules(address(dummyLTV));
        BorrowVaultModule borrowVaultModule = new BorrowVaultModule();
        CollateralVaultModule collateralVaultModule = new CollateralVaultModule();

        ModulesProvider modules = new ModulesProvider(
            ModulesState({
                borrowVaultsRead: IBorrowVaultRead(address(borrowVaultModule)),
                borrowVaultsWrite: address(borrowVaultModule),
                collateralVaultsRead: ICollateralVaultRead(address(collateralVaultModule)),
                collateralVaultsWrite: address(collateralVaultModule),
                erc20Read: IERC20Read(address(0)),
                erc20Write: address(0),
                lowLevelRebalancerRead: ILowLevelRebalanceRead(address(0)),
                lowLevelRebalancerWrite: address(0),
                auctionRead: IAuctionRead(address(0)),
                auctionWrite: address(0)
            })
        );
        ltv.setModules(modules);
    }
}
