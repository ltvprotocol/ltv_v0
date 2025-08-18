// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20Module} from "src/interfaces/reads/IERC20Module.sol";
import {IAuctionModule} from "src/interfaces/reads/IAuctionModule.sol";
import {ILowLevelRebalanceModule} from "src/interfaces/reads/ILowLevelRebalanceModule.sol";
import {IBorrowVaultModule} from "src/interfaces/reads/IBorrowVaultModule.sol";
import {ICollateralVaultModule} from "src/interfaces/reads/ICollateralVaultModule.sol";
import {IAdministrationModule} from "src/interfaces/reads/IAdministrationModule.sol";
import {IInitializeModule} from "src/interfaces/reads/IInitializeModule.sol";

interface IModules {
    function auctionModule() external view returns (IAuctionModule);
    function borrowVaultModule() external view returns (IBorrowVaultModule);
    function collateralVaultModule() external view returns (ICollateralVaultModule);
    function erc20Module() external view returns (IERC20Module);
    function lowLevelRebalanceModule() external view returns (ILowLevelRebalanceModule);
    function administrationModule() external view returns (IAdministrationModule);
    function initializeModule() external view returns (IInitializeModule);
}
