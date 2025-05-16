// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./reads/IERC20Read.sol";
import "./reads/IAuction.sol";
import "./reads/ILowLevelRebalance.sol";
import "./reads/IBorrowVault.sol";
import "./reads/ICollateralVault.sol";
import "./reads/IAdministration.sol";

interface IModules {
    function auction() external view returns (IAuction);
    function borrowVault() external view returns (IBorrowVault);
    function collateralVault() external view returns (ICollateralVault);
    function erc20() external view returns (IERC20Read);
    function lowLevelRebalance() external view returns (ILowLevelRebalance);
    function administration() external view returns (IAdministration);
    function initializeWrite() external view returns (address);
}