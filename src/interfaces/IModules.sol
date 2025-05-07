// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./reads/IERC20Read.sol";
import "./reads/IAuctionRead.sol";
import "./reads/ILowLevelRebalanceRead.sol";
import "./reads/IBorrowVaultRead.sol";
import "./reads/ICollateralVaultRead.sol";
import "./reads/IAdministration.sol";
interface IModules {
    function auctionRead() external view returns (IAuctionRead);

    function auctionWrite() external view returns (address);

    function borrowVaultsRead() external view returns (IBorrowVaultRead);

    function borrowVaultsWrite() external view returns (address);

    function collateralVaultsRead() external view returns (ICollateralVaultRead);

    function collateralVaultsWrite() external view returns (address);

    function erc20Write() external view returns (address);

    function lowLevelRebalancerRead() external view returns (ILowLevelRebalanceRead);

    function lowLevelRebalancerWrite() external view returns (address);

    function administration() external view returns (IAdministration);
}