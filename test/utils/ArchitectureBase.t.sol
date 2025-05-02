// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'forge-std/Test.sol';
import {DummyLTV} from './DummyLTV.t.sol';

import 'src/elements/BorrowVaultModule.sol';
import 'src/elements/CollateralVaultModule.sol';
import 'src/elements/AuctionModule.sol';
import 'src/elements/LowLevelRebalanceModule.sol';
import 'src/elements/ModulesProvider.sol';
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
        ModulesProvider modules = new ModulesProvider(
            ModulesState({
                borrowVaultsRead: IBorrowVaultRead(address(borrowVaultModule)),
                borrowVaultsWrite: address(borrowVaultModule),
                collateralVaultsRead: ICollateralVaultRead(address(collateralVaultModule)),
                collateralVaultsWrite: address(collateralVaultModule),
                erc20Read: IERC20Read(address(0)),
                erc20Write: address(0),
                lowLevelRebalancerRead: ILowLevelRebalanceRead(address(lowLevelRebalanceModule)),
                lowLevelRebalancerWrite: address(lowLevelRebalanceModule),
                auctionRead: IAuctionRead(address(auctionModule)),
                auctionWrite: address(auctionModule)
            })
        );
        ltv.setModules(modules);
    }
}
