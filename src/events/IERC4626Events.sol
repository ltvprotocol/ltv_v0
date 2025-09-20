// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title IERC4626Events
 * @notice Interface defining all events emitted during ERC4626 operations in the LTV vault system
 * @dev This interface contains event definitions for ERC4626-related operations,
 *      including deposit, withdraw, deposit collateral, and withdraw collateral events.
 *      These events provide transparency and allow external systems to track ERC4626 activities.
 * @author LTV Protocol
 */
interface IERC4626Events {
    /**
     * @notice Emitted when borrow assets are deposited and shares are minted
     * @param sender The address that initiated the deposit
     * @param owner The address that receives the minted shares
     * @param assets The amount of borrow assets deposited
     * @param shares The number of shares minted
     * @dev This event is emitted when borrow assets are deposited and shares are minted
     */
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    /**
     * @notice Emitted when borrow assets are withdrawn and shares are burned
     * @param sender The address that initiated the withdrawal
     * @param receiver The address that receives the withdrawn assets
     * @param owner The address whose shares are burned
     * @param assets The amount of borrow assets withdrawn
     * @param shares The number of shares burned
     * @dev This event is emitted when borrow assets are withdrawn and shares are burned
     */
    event Withdraw(
        address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );
    /**
     * @notice Emitted when collateral assets are deposited and shares are minted
     * @param sender The address that initiated the deposit
     * @param owner The address that receives the minted shares
     * @param collateralAssets The amount of collateral assets deposited
     * @param shares The number of shares minted
     * @dev This event is emitted when collateral assets are deposited and shares are minted
     */
    event DepositCollateral(address indexed sender, address indexed owner, uint256 collateralAssets, uint256 shares);
    /**
     * @notice Emitted when collateral assets are withdrawn and shares are burned
     * @param sender The address that initiated the withdrawal
     * @param receiver The address that receives the withdrawn assets
     * @param owner The address whose shares are burned
     * @param collateralAssets The amount of collateral assets withdrawn
     * @param shares The number of shares burned
     * @dev This event is emitted when collateral assets are withdrawn and shares are burned
     */
    event WithdrawCollateral(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 collateralAssets,
        uint256 shares
    );
}
