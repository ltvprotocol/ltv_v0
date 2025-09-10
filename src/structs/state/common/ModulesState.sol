// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IBorrowVaultModule} from "../../../interfaces/reads/IBorrowVaultModule.sol";
import {ICollateralVaultModule} from "../../../interfaces/reads/ICollateralVaultModule.sol";
import {ILowLevelRebalanceModule} from "../../../interfaces/reads/ILowLevelRebalanceModule.sol";
import {IAuctionModule} from "../../../interfaces/reads/IAuctionModule.sol";
import {IERC20Module} from "../../../interfaces/reads/IERC20Module.sol";
import {IInitializeModule} from "../../../interfaces/writes/IInitializeModule.sol";
import {IAdministrationModule} from "../../../interfaces/reads/IAdministrationModule.sol";

/**
 * @title ModulesState
 * @notice This struct needed for module state calculations
 */
struct ModulesState {
    IBorrowVaultModule borrowVaultModule;
    ICollateralVaultModule collateralVaultModule;
    ILowLevelRebalanceModule lowLevelRebalanceModule;
    IAuctionModule auctionModule;
    IAdministrationModule administrationModule;
    IERC20Module erc20Module;
    IInitializeModule initializeModule;
}
