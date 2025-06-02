// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./BaseTest.t.sol";
import "./modules/DummyBorrowVaultModule.t.sol";
import "./modules/DummyCollateralVaultModule.t.sol";
import "./modules/DummyERC20Module.t.sol";
import "./modules/DummyLowLevelRebalanceModule.t.sol";

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
            lowLevelRebalanceModule: ILowLevelRebalanceModule(address(lowLevelRebalanceModule))
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
