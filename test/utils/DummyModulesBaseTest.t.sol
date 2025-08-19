// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, BaseTestInit} from "test/utils/BaseTest.t.sol";
import {DummyLTV} from "test/utils/DummyLTV.t.sol";
import {IAdministrationModule} from "src/interfaces/reads/IAdministrationModule.sol";
import {IAuctionModule} from "src/interfaces/reads/IAuctionModule.sol";
import {IERC20Module} from "src/interfaces/reads/IERC20Module.sol";
import {ICollateralVaultModule} from "src/interfaces/reads/ICollateralVaultModule.sol";
import {IBorrowVaultModule} from "src/interfaces/reads/IBorrowVaultModule.sol";
import {ILowLevelRebalanceModule} from "src/interfaces/reads/ILowLevelRebalanceModule.sol";
import {IInitializeModule} from "src/interfaces/reads/IInitializeModule.sol";
import {ModulesState} from "src/structs/state/ModulesState.sol";
import {ModulesProvider} from "src/elements/ModulesProvider.sol";
import {DummyBorrowVaultModule} from "test/utils/modules/DummyBorrowVaultModule.t.sol";
import {DummyCollateralVaultModule} from "test/utils/modules/DummyCollateralVaultModule.t.sol";
import {DummyERC20Module} from "test/utils/modules/DummyERC20Module.t.sol";
import {DummyLowLevelRebalanceModule} from "test/utils/modules/DummyLowLevelRebalanceModule.t.sol";

contract DummyModulesBaseTest is BaseTest {
    DummyLTV public dummyLTV;

    function replaceWithDummyModules() internal {
        DummyBorrowVaultModule borrowVaultModule = new DummyBorrowVaultModule();
        DummyCollateralVaultModule collateralVaultModule = new DummyCollateralVaultModule();
        DummyERC20Module erc20Module = new DummyERC20Module();
        DummyLowLevelRebalanceModule lowLevelRebalanceModule = new DummyLowLevelRebalanceModule();

        ModulesState memory modulesState = ModulesState({
            administrationModule: IAdministrationModule(address(ltv.modules().administrationModule())),
            auctionModule: IAuctionModule(address(ltv.modules().auctionModule())),
            borrowVaultModule: IBorrowVaultModule(address(borrowVaultModule)),
            collateralVaultModule: ICollateralVaultModule(address(collateralVaultModule)),
            erc20Module: IERC20Module(address(erc20Module)),
            lowLevelRebalanceModule: ILowLevelRebalanceModule(address(lowLevelRebalanceModule)),
            initializeModule: IInitializeModule(address(ltv.modules().initializeModule()))
        });

        vm.startPrank(ltv.owner());
        ltv.setModules(new ModulesProvider(modulesState));
        vm.stopPrank();
    }

    function initializeDummyTest(BaseTestInit memory init) internal {
        initializeTest(init);

        replaceWithDummyModules();

        dummyLTV = ltv;
    }
}
