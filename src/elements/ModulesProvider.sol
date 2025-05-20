// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/structs/state/ModulesState.sol';
import 'src/interfaces/IModules.sol';
import 'src/interfaces/reads/IBorrowVaultModule.sol';

contract ModulesProvider is IModules {
    constructor(ModulesState memory state) {
        borrowVaultModule = state.borrowVaultModule;
        collateralVaultModule = state.collateralVaultModule;
        lowLevelRebalanceModule = state.lowLevelRebalanceModule;
        auctionModule = state.auctionModule;
        erc20Module = state.erc20Module;
        administrationModule = state.administrationModule;
    }

    IBorrowVaultModule public borrowVaultModule;
    ICollateralVaultModule public collateralVaultModule;
    ILowLevelRebalanceModule public lowLevelRebalanceModule;
    IAuctionModule public auctionModule;
    IERC20Module public erc20Module;
    IAdministrationModule public administrationModule;
}