// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20Module} from "./reads/IERC20Module.sol";
import {IAuctionModule} from "./reads/IAuctionModule.sol";
import {ILowLevelRebalanceModule} from "./reads/ILowLevelRebalanceModule.sol";
import {IBorrowVaultModule} from "./reads/IBorrowVaultModule.sol";
import {ICollateralVaultModule} from "./reads/ICollateralVaultModule.sol";
import {IInitializeModule} from "./writes/IInitializeModule.sol";
import {IAdministrationModule} from "./reads/IAdministrationModule.sol";

interface IModules {
    function auctionModule() external view returns (IAuctionModule);
    function borrowVaultModule() external view returns (IBorrowVaultModule);
    function collateralVaultModule() external view returns (ICollateralVaultModule);
    function erc20Module() external view returns (IERC20Module);
    function lowLevelRebalanceModule() external view returns (ILowLevelRebalanceModule);
    function administrationModule() external view returns (IAdministrationModule);
    function initializeModule() external view returns (IInitializeModule);
}
