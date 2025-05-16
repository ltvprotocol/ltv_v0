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
        initializeModule = state.initializeModule;
    }

    IBorrowVaultModule public borrowVaultModule;
    ICollateralVault public collateralVaultModule;
    ILowLevelRebalance public lowLevelRebalanceModule;
    IAuction public auctionModule;
    IERC20Read public erc20Module;
    IAdministration public administrationModule;
    address public initializeModule;
}
