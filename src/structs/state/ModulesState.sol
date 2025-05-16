// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/interfaces/reads/IBorrowVaultModule.sol';
import 'src/interfaces/reads/ICollateralVault.sol';
import 'src/interfaces/reads/ILowLevelRebalance.sol';
import 'src/interfaces/reads/IAuction.sol';
import 'src/interfaces/reads/IAdministration.sol';
import 'src/interfaces/reads/IERC20Read.sol';

struct ModulesState {
    IBorrowVaultModule borrowVaultModule;
    ICollateralVault collateralVaultModule;
    ILowLevelRebalance lowLevelRebalanceModule;
    IAuction auctionModule;
    IAdministration administrationModule;
    IERC20Read erc20Module;
    address initializeModule;
}
