// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./reads/IERC20Read.sol";
import "./reads/IAuction.sol";
import "./reads/ILowLevelRebalance.sol";
import "./reads/IBorrowVaultModule.sol";
import "./reads/ICollateralVault.sol";
import "./reads/IAdministration.sol";

interface IModules {
    function auctionModule() external view returns (IAuction);
    function borrowVaultModule() external view returns (IBorrowVaultModule);
    function collateralVaultModule() external view returns (ICollateralVault);
    function erc20Module() external view returns (IERC20Read);
    function lowLevelRebalanceModule() external view returns (ILowLevelRebalance);
    function administrationModule() external view returns (IAdministration);
    function initializeModule() external view returns (address);
}