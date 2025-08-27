// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {ModulesProvider} from "../../src/elements/ModulesProvider.sol";
import {console} from "forge-std/console.sol";
import {ModulesState} from "../../src/structs/state/ModulesState.sol";
import {IERC20Module} from "../../src/interfaces/reads/IERC20Module.sol";
import {IBorrowVaultModule} from "../../src/interfaces/reads/IBorrowVaultModule.sol";
import {ICollateralVaultModule} from "../../src/interfaces/reads/ICollateralVaultModule.sol";
import {ILowLevelRebalanceModule} from "../../src/interfaces/reads/ILowLevelRebalanceModule.sol";
import {IAuctionModule} from "../../src/interfaces/reads/IAuctionModule.sol";
import {IAdministrationModule} from "../../src/interfaces/reads/IAdministrationModule.sol";
import {IInitializeModule} from "../../src/interfaces/reads/IInitializeModule.sol";

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
