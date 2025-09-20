// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20Module} from "./reads/IERC20Module.sol";
import {IAuctionModule} from "./reads/IAuctionModule.sol";
import {ILowLevelRebalanceModule} from "./reads/ILowLevelRebalanceModule.sol";
import {IBorrowVaultModule} from "./reads/IBorrowVaultModule.sol";
import {ICollateralVaultModule} from "./reads/ICollateralVaultModule.sol";
import {IInitializeModule} from "./writes/IInitializeModule.sol";
import {IAdministrationModule} from "./reads/IAdministrationModule.sol";

/**
 * @title IModules
 * @notice Interface defines modules structure for integration with LTV protocol.
 */
interface IModules {
    /**
     * @dev Get the auction module
     */
    function auctionModule() external view returns (IAuctionModule);
    /**
     * @dev Get the borrow vault module
     */
    function borrowVaultModule() external view returns (IBorrowVaultModule);
    /**
     * @dev Get the collateral vault module
     */
    function collateralVaultModule() external view returns (ICollateralVaultModule);
    /**
     * @dev Get the erc20 module
     */
    function erc20Module() external view returns (IERC20Module);
    /**
     * @dev Get the low level rebalance module
     */
    function lowLevelRebalanceModule() external view returns (ILowLevelRebalanceModule);
    /**
     * @dev Get the administration module
     */
    function administrationModule() external view returns (IAdministrationModule);
    /**
     * @dev Get the initialize module
     */
    function initializeModule() external view returns (IInitializeModule);
}
