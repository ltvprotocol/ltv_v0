// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./reads/IERC20Module.sol";
import "./reads/IAuctionModule.sol";
import "./reads/ILowLevelRebalanceModule.sol";
import "./reads/IBorrowVaultModule.sol";
import "./reads/ICollateralVaultModule.sol";
import "./reads/IAdministrationModule.sol";
import "./reads/IInitializeModule.sol";

interface IModules {
    function auctionModule() external view returns (IAuctionModule);
    function borrowVaultModule() external view returns (IBorrowVaultModule);
    function collateralVaultModule() external view returns (ICollateralVaultModule);
    function erc20Module() external view returns (IERC20Module);
    function lowLevelRebalanceModule() external view returns (ILowLevelRebalanceModule);
    function administrationModule() external view returns (IAdministrationModule);
    function initializeModule() external view returns (IInitializeModule);
}
