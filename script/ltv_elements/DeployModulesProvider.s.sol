// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../utils/BaseScript.s.sol";
import "../../src/elements/ModulesProvider.sol";

contract DeployModulesProvider is BaseScript {
    function deploy() internal override {
        ModulesProvider modulesProvider = new ModulesProvider{salt: bytes32(0)}(getState());
        console.log("ModulesProvider deployed at: ", address(modulesProvider));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        ModulesState memory state = getState();
        return keccak256(abi.encodePacked(type(ModulesProvider).creationCode, abi.encode(state)));
    }

    function getState() internal view returns (ModulesState memory) {
        address erc20Module = vm.envAddress("ERC20_MODULE");
        address borrowVaultModule = vm.envAddress("BORROW_VAULT_MODULE");
        address collateralVaultModule = vm.envAddress("COLLATERAL_VAULT_MODULE");
        address lowLevelRebalanceModule = vm.envAddress("LOW_LEVEL_REBALANCE_MODULE");
        address auctionModule = vm.envAddress("AUCTION_MODULE");
        address administrationModule = vm.envAddress("ADMINISTRATION_MODULE");
        address initializeModule = vm.envAddress("INITIALIZE_MODULE");
        return ModulesState({
            erc20Module: IERC20Module(erc20Module),
            borrowVaultModule: IBorrowVaultModule(borrowVaultModule),
            collateralVaultModule: ICollateralVaultModule(collateralVaultModule),
            lowLevelRebalanceModule: ILowLevelRebalanceModule(lowLevelRebalanceModule),
            auctionModule: IAuctionModule(auctionModule),
            administrationModule: IAdministrationModule(administrationModule),
            initializeModule: IInitializeModule(initializeModule)
        });
    }
}
