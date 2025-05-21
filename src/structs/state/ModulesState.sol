// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/interfaces/reads/IBorrowVaultModule.sol';
import 'src/interfaces/reads/ICollateralVaultModule.sol';
import 'src/interfaces/reads/ILowLevelRebalanceModule.sol';
import 'src/interfaces/reads/IAuctionModule.sol';
import 'src/interfaces/reads/IAdministrationModule.sol';
import 'src/interfaces/reads/IERC20Module.sol';

struct ModulesState {
    IBorrowVaultModule borrowVaultModule;
    ICollateralVaultModule collateralVaultModule;
    ILowLevelRebalanceModule lowLevelRebalanceModule;
    IAuctionModule auctionModule;
    IAdministrationModule administrationModule;
    IERC20Module erc20Module;
}
