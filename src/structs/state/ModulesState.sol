// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IBorrowVaultModule} from "src/interfaces/reads/IBorrowVaultModule.sol";
import {ICollateralVaultModule} from "src/interfaces/reads/ICollateralVaultModule.sol";
import {ILowLevelRebalanceModule} from "src/interfaces/reads/ILowLevelRebalanceModule.sol";
import {IAuctionModule} from "src/interfaces/reads/IAuctionModule.sol";
import {IAdministrationModule} from "src/interfaces/reads/IAdministrationModule.sol";
import {IERC20Module} from "src/interfaces/reads/IERC20Module.sol";
import {IInitializeModule} from "src/interfaces/reads/IInitializeModule.sol";

struct ModulesState {
    IBorrowVaultModule borrowVaultModule;
    ICollateralVaultModule collateralVaultModule;
    ILowLevelRebalanceModule lowLevelRebalanceModule;
    IAuctionModule auctionModule;
    IAdministrationModule administrationModule;
    IERC20Module erc20Module;
    IInitializeModule initializeModule;
}
