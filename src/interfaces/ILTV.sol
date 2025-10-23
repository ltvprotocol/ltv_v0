// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IModules} from "src/interfaces/IModules.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";
import {IVaultErrors} from "src/errors/IVaultErrors.sol";
import {ILowLevelRebalanceErrors} from "src/errors/ILowLevelRebalanceErrors.sol";
import {IAuctionErrors} from "src/errors/IAuctionErrors.sol";
import {IAdministrationEvents} from "src/events/IAdministrationEvents.sol";
import {IAuctionEvent} from "src/events/IAuctionEvent.sol";
import {IERC4626Events} from "src/events/IERC4626Events.sol";
import {IERC20Events} from "src/events/IERC20Events.sol";
import {ILowLevelRebalanceEvent} from "src/events/ILowLevelRebalanceEvent.sol";
import {StateInitData} from "src/structs/state/initialize/StateInitData.sol";

/**
 * @title ILTV
 * @notice Main interface for the LTV protocol. This interface defines all the public function signatures
 *         and events that the LTV protocol implements.
 * This interface includes:
 * - EIP-4626 Vault Standard functions (deposit, withdraw, mint, redeem)
 * - EIP-4626 Collateral Vault Extension functions
 * - ERC-20 Standard functions
 * - Auction system functions
 * - Low-level rebalancing functions
 * - Administration and configuration functions
 * - State querying functions
 */
interface ILTV is
    IAdministrationErrors,
    IVaultErrors,
    ILowLevelRebalanceErrors,
    IAuctionErrors,
    IAdministrationEvents,
    ILowLevelRebalanceEvent,
    IAuctionEvent,
    IERC4626Events,
    IERC20Events
{
    // ========================================
    // EIP-4626 VAULT STANDARD FUNCTIONS
    // ========================================

    /**
     * @notice Returns the vault's underlying asset address
     * @return The address of the underlying asset (borrow token)
     */
    function asset() external view returns (address);

    /**
     * @notice Returns the total amount of borrowed assets in the vault
     * @return The total amount of borrowed assets in the vault, including real and future auction assets
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice Returns the total amount of borrow assets managed by the vault with context-aware pricing
     * @param isDeposit Whether this is for deposit operations (true) or withdrawal operations (false)
     * @return The total amount of borrow assets managed by the vault
     * @dev When isDeposit = true, uses optimistic pricing (rounds up collateral, rounds down borrow).
     *      When isDeposit = false, uses conservative pricing (rounds down collateral, rounds up borrow).
     */
    function totalAssets(bool isDeposit) external view returns (uint256);

    /**
     * @notice Calculates how many vault shares are obtained for a certain amount of borrowed assets
     * @param assets The amount of borrowed assets to convert
     * @return The number of shares based on the assets
     */
    function convertToShares(uint256 assets) external view returns (uint256);

    /**
     * @notice Calculates how many borrowed assets are obtained for a certain number of vault shares
     * @param shares The number of shares to convert
     * @return The amount of borrowed assets based on the shares
     */
    function convertToAssets(uint256 shares) external view returns (uint256);

    /**
     * @notice Returns the maximum borrowed assets that the receiver can deposit
     * @param receiver The address to check deposit limits
     * @return The maximum amount of borrowed assets that can be deposited
     */
    function maxDeposit(address receiver) external view returns (uint256);

    /**
     * @notice Returns the maximum vault shares that can be minted for the receiver
     * @param receiver The address to check mint limits
     * @return The maximum number of shares that can be minted for the receiver
     */
    function maxMint(address receiver) external view returns (uint256);

    /**
     * @notice Returns the maximum borrowed assets the owner can withdraw
     * @param owner The address to check withdrawal limits
     * @return The maximum amount of borrowed assets that can be withdrawn
     */
    function maxWithdraw(address owner) external view returns (uint256);

    /**
     * @notice Returns the maximum shares the owner can redeem
     * @param owner The address to check redemption limits
     * @return The maximum number of shares that can be redeemed
     */
    function maxRedeem(address owner) external view returns (uint256);

    /**
     * @notice Estimates how many vault shares you get for depositing a specified amount of borrowed assets
     * @param assets The amount of borrowed assets to deposit
     * @return The estimated number of shares received
     */
    function previewDeposit(uint256 assets) external view returns (uint256);

    /**
     * @notice Estimates how many borrowed assets are needed to mint a specified number of shares
     * @param shares The number of shares to mint
     * @return The estimated amount of borrowed assets needed
     */
    function previewMint(uint256 shares) external view returns (uint256);

    /**
     * @notice Estimates how many shares must be burned to withdraw the specified amount of borrowed assets
     * @param assets The amount of borrowed assets to withdraw
     * @return The estimated number of shares to be burned
     */
    function previewWithdraw(uint256 assets) external view returns (uint256);

    /**
     * @notice Estimates how many borrowed assets to get for redeeming the specified number of shares
     * @param shares The number of shares to redeem
     * @return The estimated amount of borrowed assets to be received
     */
    function previewRedeem(uint256 shares) external view returns (uint256);

    /**
     * @notice Deposits borrowed assets and mints vault shares to the receiver
     * @param assets The amount of borrowed assets to deposit
     * @param receiver The address to receive the minted shares
     * @return The number of shares minted for the receiver
     * @dev This may trigger rebalancing to maintain the target loan-to-value (LTV) ratio
     */
    function deposit(uint256 assets, address receiver) external returns (uint256);

    /**
     * @notice Mints vault shares in exchange for borrowed assets
     * @param shares The number of shares to mint
     * @param receiver The address to receive the minted shares
     * @return The amount of borrowed assets used to mint the shares
     * @dev The required asset amount is calculated based on current exchange rates
     */
    function mint(uint256 shares, address receiver) external returns (uint256);

    /**
     * @notice Withdraws borrowed assets by burning shares from an owner
     * @param assets The amount of borrowed assets to withdraw
     * @param receiver The address to receive the withdrawn assets
     * @param owner The address whose shares will be burned
     * @return The number of shares burned from the owner
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256);

    /**
     * @notice Redeems shares and transfers borrowed assets to a receiver
     * @param shares The number of shares to redeem
     * @param receiver The address to receive the assets
     * @param owner The address whose shares will be burned
     * @return The amount of borrowed assets transferred to the receiver
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);

    // ========================================
    // EIP-4626 COLLATERAL VAULT EXTENSION
    // ========================================

    /**
     * @notice Returns the maximum collateral assets the receiver can deposit
     * @param receiver The address to check for how much collateral can be deposited
     * @return The maximum amount of collateral that can be deposited
     */
    function maxDepositCollateral(address receiver) external view returns (uint256);

    /**
     * @notice Returns how many collateral shares can be minted for the receiver
     * @param receiver The address to check for how much collateral can be minted
     * @return The maximum number of collateral shares that can be minted
     */
    function maxMintCollateral(address receiver) external view returns (uint256);

    /**
     * @notice Returns how many collateral shares the owner can redeem
     * @param owner The address to check for how much collateral can be redeemed
     * @return The maximum number of collateral shares that can be redeemed
     */
    function maxRedeemCollateral(address owner) external view returns (uint256);

    /**
     * @notice Returns the maximum collateral assets the owner can withdraw
     * @param owner The address to check for how much collateral can be withdrawn
     * @return The maximum amount of collateral assets that can be withdrawn
     */
    function maxWithdrawCollateral(address owner) external view returns (uint256);

    /**
     * @notice Estimates how many collateral shares to get for depositing a specific amount of collateral assets
     * @param collateralAssets The amount of collateral assets to deposit
     * @return The estimated number of collateral shares to receive
     */
    function previewDepositCollateral(uint256 collateralAssets) external view returns (uint256);

    /**
     * @notice Estimates how much collateral is required to mint a specific number of shares
     * @param shares The number of collateral shares to mint
     * @return The estimated amount of collateral assets needed
     */
    function previewMintCollateral(uint256 shares) external view returns (uint256);

    /**
     * @notice Estimates how many collateral shares that need to be burned to withdraw a specific amount of collateral assets
     * @param collateralAssets The amount of collateral assets to withdraw
     * @return The estimated number of collateral shares that will be burned
     */
    function previewWithdrawCollateral(uint256 collateralAssets) external view returns (uint256);

    /**
     * @notice Estimates how much collateral to get for redeeming a specific number of shares
     * @param shares The number of collateral shares to redeem
     * @return The estimated amount of collateral assets to receive
     */
    function previewRedeemCollateral(uint256 shares) external view returns (uint256);

    /**
     * @notice Deposits collateral assets and mints collateral shares to the receiver
     * @param collateralAssets The amount of collateral assets to deposit
     * @param receiver The address to receive the minted collateral shares
     * @return The number of collateral shares minted to the receiver
     */
    function depositCollateral(uint256 collateralAssets, address receiver) external returns (uint256);

    /**
     * @notice Mints collateral shares in exchange for collateral assets
     * @param shares The number of collateral shares to mint
     * @param receiver The address to receive the minted shares
     * @return The amount of collateral assets used to mint the shares
     */
    function mintCollateral(uint256 shares, address receiver) external returns (uint256);

    /**
     * @notice Withdraws collateral assets by burning collateral shares from the owner
     * @param collateralAssets The amount of collateral assets to withdraw
     * @param receiver The address to receive the withdrawn collateral assets
     * @param owner The address whose collateral shares will be burned
     * @return The number of collateral shares burned from the owner
     */
    function withdrawCollateral(uint256 collateralAssets, address receiver, address owner) external returns (uint256);

    /**
     * @notice Redeems collateral shares and transfers the corresponding collateral assets to the receiver
     * @param shares The number of collateral shares to redeem
     * @param receiver The address to receive the withdrawn collateral assets
     * @param owner The address whose collateral shares will be burned
     * @return The amount of collateral assets transferred to the receiver
     */
    function redeemCollateral(uint256 shares, address receiver, address owner) external returns (uint256);

    /**
     * @notice Returns the total collateral assets in the vault using conservative pricing (isDeposit = false)
     * @return The total amount of collateral assets managed by the vault
     */
    function totalAssetsCollateral() external view returns (uint256);

    /**
     * @notice Returns the total collateral assets with context-aware pricing
     * @param isDeposit Whether this is for a deposit operation (true) or withdrawal operation (false)
     * @return The total amount of collateral assets managed by the vault
     * @dev Use isDeposit = true for deposit operations (optimistic pricing) and isDeposit = false for withdrawal operations (conservative pricing)
     */
    function totalAssetsCollateral(bool isDeposit) external view returns (uint256);

    // ========================================
    // ERC-20 STANDARD FUNCTIONS
    // ========================================

    /**
     * @notice Returns the vault share token balance of the specified address
     * @param owner The address to check the balance for
     * @return The token balance of the owner
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Returns the total supply of vault share tokens
     * @return The total supply of vault share tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the number of decimal places for the vault share token
     * @return The number of decimal places for the token
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the name of the vault share token
     * @return The token name
     */
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the vault share token
     * @return The token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Returns the remaining number of tokens that a spender can use on behalf of an owner
     * @param owner The address that owns the tokens
     * @param spender The address that can spend the tokens
     * @return The remaining allowance
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Approves a spender to use a specified amount of tokens
     * @param spender The address to approve
     * @param amount The amount of tokens to approve
     * @return True if the approval was successful
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Transfers tokens to a recipient
     * @param recipient The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     * @return True if the transfer was successful
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @notice Transfers tokens from a sender to a recipient
     * @param sender The address to transfer tokens from
     * @param recipient The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     * @return True if the transfer was successful
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // ========================================
    // AUCTION SYSTEM FUNCT-IONS
    // ========================================

    /**
     * @notice Returns the timestamp when the current auction started, or 0 if no auction is active
     * @return The timestamp when the auction started
     */
    function startAuction() external view returns (uint56);

    /**
     * @notice Returns the duration of the auction
     * @return The auction duration in seconds
     */
    function auctionDuration() external view returns (uint24);

    /**
     * @notice Estimates the amount of borrow assets a user needs to give or receive to execute the auction with the specified delta
     * @param deltaUserBorrowAssets The change in user borrow assets (positive to receive, negative to provide)
     * @return The estimated amount of collateral assets user needs to give/receive
     */
    function previewExecuteAuctionBorrow(int256 deltaUserBorrowAssets) external view returns (int256);

    /**
     * @notice Estimates the amount of collateral assets a user needs to give or receive to execute the auction with the specified delta
     * @param deltaUserCollateralAssets The change in user collateral assets (positive to receive, negative to provide)
     * @return The estimated amount of borrow assets user needs to give/receive
     */
    function previewExecuteAuctionCollateral(int256 deltaUserCollateralAssets) external view returns (int256);

    /**
     * @notice Executes an auction for borrow assets, allowing users to participate in rebalancing for rewards
     * @param deltaUserBorrowAssets The change in user borrow assets (positive to receive, negative to provide)
     * @return The actual amount of collateral assets transferred
     */
    function executeAuctionBorrow(int256 deltaUserBorrowAssets) external returns (int256);

    /**
     * @notice Executes an auction for collateral assets, allowing users to participate in rebalancing for rewards
     * @param deltaUserCollateralAssets The change in user collateral assets (positive to receive, negative to provide)
     * @return The actual amount of borrow assets transferred
     */
    function executeAuctionCollateral(int256 deltaUserCollateralAssets) external returns (int256);

    // ========================================
    // LOW LEVEL REBALANCE FUNCTIONS
    // ========================================

    /**
     * @notice Returns the maximum amount of borrow assets that can be used in low level rebalance
     * @return The maximum amount of borrow assets that can be withdrawn (positive) or deposited (negative) in a low level rebalance operation
     */
    function maxLowLevelRebalanceBorrow() external view returns (int256);

    /**
     * @notice Returns the maximum amount of collateral assets that can be used in low level rebalance
     * @return The maximum amount of collateral assets that can be withdrawn (positive) or deposited (negative) in a low level rebalance operation
     */
    function maxLowLevelRebalanceCollateral() external view returns (int256);

    /**
     * @notice Returns the maximum amount of shares that can be minted or burned in low level rebalance
     * @return The maximum amount of shares that can be minted (positive) or burned (negative) in a low level rebalance operation
     */
    function maxLowLevelRebalanceShares() external view returns (int256);

    /**
     * @notice Previews low level rebalance execution with input in borrow assets
     * @param deltaBorrow The amount of borrow assets to withdraw or deposit (negative to send borrow assets)
     * @return deltaCollateral The amount of collateral assets user will receive or provide
     * @return deltaShares The amount of shares user will receive or burn
     * @dev Negative deltaCollateral means protocol sends collateral to user, positive means user provides collateral.
     *      Positive deltaShares means user receives shares, negative means shares are burned.
     */
    function previewLowLevelRebalanceBorrow(int256 deltaBorrow)
        external
        view
        returns (int256 deltaCollateral, int256 deltaShares);

    /**
     * @notice Previews low level rebalance execution with input in collateral assets
     * @param deltaCollateral The amount of collateral assets to withdraw or deposit (positive to send collateral assets)
     * @return deltaBorrow The amount of borrow assets user will receive or provide
     * @return deltaShares The amount of shares user will receive or burn
     * @dev Positive deltaBorrow means protocol sends borrow assets to user, negative means user provides borrow assets.
     */
    function previewLowLevelRebalanceCollateral(int256 deltaCollateral)
        external
        view
        returns (int256 deltaBorrow, int256 deltaShares);

    /**
     * @notice Previews low level rebalance execution with input in shares
     * @param deltaShares The amount of shares to mint or burn (positive for mint)
     * @return deltaCollateral The amount of collateral assets user will receive or provide
     * @return deltaBorrow The amount of borrow assets user will receive or provide
     * @dev Positive deltaShares mints shares, negative burns shares.
     */
    function previewLowLevelRebalanceShares(int256 deltaShares)
        external
        view
        returns (int256 deltaCollateral, int256 deltaBorrow);

    /**
     * @notice Previews low level rebalance with hint to optimize gas usage (borrow input)
     * @param deltaBorrow The amount of borrow assets to withdraw or deposit (negative to send borrow assets)
     * @param isSharesPositiveHint The hint indicating if user expects to mint shares (saves gas)
     * @return deltaCollateral The amount of collateral assets user will receive or provide
     * @return deltaShares The amount of shares user will receive or burn
     * @dev This function is the same as previewLowLevelRebalanceBorrow but with a hint to optimize gas usage.
     */
    function previewLowLevelRebalanceBorrowHint(int256 deltaBorrow, bool isSharesPositiveHint)
        external
        view
        returns (int256 deltaCollateral, int256 deltaShares);

    /**
     * @notice Previews low level rebalance with hint to optimize gas usage (collateral input)
     * @param deltaCollateral The amount of collateral assets to withdraw or deposit (positive to send collateral assets)
     * @param isSharesPositiveHint The hint indicating if user expects to mint shares (saves gas)
     * @return deltaBorrow The amount of borrow assets user will receive or provide
     * @return deltaShares The amount of shares user will receive or burn
     * @dev This function is the same as previewLowLevelRebalanceCollateral but with a hint to optimize gas usage.
     */
    function previewLowLevelRebalanceCollateralHint(int256 deltaCollateral, bool isSharesPositiveHint)
        external
        view
        returns (int256 deltaBorrow, int256 deltaShares);

    /**
     * @notice Executes low level rebalance with input in borrow assets
     * @param deltaBorrow The amount of borrow assets to withdraw or deposit (negative to send borrow assets)
     * @return deltaCollateral The amount of collateral assets transferred
     * @return deltaShares The amount of shares minted or burned
     * @dev This is a core rebalancing function that maintains the target LTV ratio.
     */
    function executeLowLevelRebalanceBorrow(int256 deltaBorrow)
        external
        returns (int256 deltaCollateral, int256 deltaShares);

    /**
     * @notice Executes low level rebalance with input in collateral assets
     * @param deltaCollateral The amount of collateral assets to withdraw or deposit (positive to send collateral assets)
     * @return deltaBorrow The amount of borrow assets transferred
     * @return deltaShares The amount of shares minted or burned
     */
    function executeLowLevelRebalanceCollateral(int256 deltaCollateral)
        external
        returns (int256 deltaBorrow, int256 deltaShares);

    /**
     * @notice Executes low level rebalance with input in shares
     * @param deltaShares The amount of shares to mint or burn (positive for mint)
     * @return deltaCollateral The amount of collateral assets transferred
     * @return deltaBorrow The amount of borrow assets transferred
     */
    function executeLowLevelRebalanceShares(int256 deltaShares)
        external
        returns (int256 deltaCollateral, int256 deltaBorrow);

    /**
     * @notice Executes low level rebalance with hint to optimize gas usage (borrow input)
     * @param deltaBorrow The amount of borrow assets to withdraw or deposit (negative to send borrow assets)
     * @param isSharesPositiveHint The hint indicating if user expects to mint shares
     * @return deltaCollateral The amount of collateral assets transferred
     * @return deltaShares The amount of shares minted or burned
     * @dev This function is the same as executeLowLevelRebalanceBorrow but with a hint to optimize gas usage.
     */
    function executeLowLevelRebalanceBorrowHint(int256 deltaBorrow, bool isSharesPositiveHint)
        external
        returns (int256 deltaCollateral, int256 deltaShares);

    /**
     * @notice Executes low level rebalance with hint to optimize gas usage (collateral input)
     * @param deltaCollateral The amount of collateral assets to withdraw or deposit (positive to send collateral assets)
     * @param isSharesPositiveHint The hint indicating if user expects to mint shares
     * @return deltaBorrow The amount of borrow assets transferred
     * @return deltaShares The amount of shares minted or burned
     * @dev This function is the same as executeLowLevelRebalanceCollateral but with a hint to optimize gas usage.
     */
    function executeLowLevelRebalanceCollateralHint(int256 deltaCollateral, bool isSharesPositiveHint)
        external
        returns (int256 deltaBorrow, int256 deltaShares);

    // ========================================
    // STATE QUERYING FUNCTIONS
    // ========================================

    /**
     * @notice Returns the address of the borrow token (e.g., USDC, DAI)
     * @return The borrow token contract address
     */
    function borrowToken() external view returns (address);

    /**
     * @notice Returns the address of the collateral token (e.g., WETH, WBTC)
     * @return The collateral token contract address
     */
    function collateralToken() external view returns (address);

    /**
     * @notice Returns the current amount of borrow assets in the auction system
     * @return The current auction borrow assets
     */
    function futureBorrowAssets() external view returns (int256);

    /**
     * @notice Returns the current amount of collateral assets in the auction system
     * @return The current auction collateral assets
     */
    function futureCollateralAssets() external view returns (int256);

    /**
     * @notice Returns the current auction reward in borrow assets
     * @return The current auction reward in borrow assets
     */
    function futureRewardBorrowAssets() external view returns (int256);

    /**
     * @notice Returns the current auction reward in collateral assets
     * @return The current auction reward in collateral assets
     */
    function futureRewardCollateralAssets() external view returns (int256);

    /**
     * @notice Returns protocol's current debt in lending protocol in borrow assets
     * @param isDeposit Rounding hint for the calculation. Result can be different
     * depending on estimating for deposit or withdraw.
     * @return The current debt in borrow assets
     */
    function getRealBorrowAssets(bool isDeposit) external view returns (uint256);

    /**
     * @notice Returns protocol's current collateral in lending protocol in collateral assets
     * @param isDeposit Rounding hint for the calculation. Result can be different
     * depending on estimating for deposit or withdraw.
     * @return The current collateral in collateral assets
     */
    function getRealCollateralAssets(bool isDeposit) external view returns (uint256);

    /**
     * @notice Returns the maximum safe loan-to-value ratio (numerator)
     * @return The maximum safe LTV numerator
     */
    function maxSafeLtvDividend() external view returns (uint16);

    /**
     * @notice Returns the maximum safe loan-to-value ratio (denominator)
     * @return The maximum safe LTV denominator
     */
    function maxSafeLtvDivider() external view returns (uint16);

    /**
     * @notice Returns the minimum profitable LTV (numerator)
     * @return The minimum profitable LTV numerator
     */
    function minProfitLtvDividend() external view returns (uint16);

    /**
     * @notice Returns the minimum profitable LTV (denominator)
     * @return The minimum profitable LTV denominator
     */
    function minProfitLtvDivider() external view returns (uint16);

    /**
     * @notice Returns the target loan-to-value ratio (numerator)
     * @return The target LTV numerator
     */
    function targetLtvDividend() external view returns (uint16);

    /**
     * @notice Returns the target loan-to-value ratio (denominator)
     * @return The target LTV denominator
     */
    function targetLtvDivider() external view returns (uint16);

    /**
     * @notice Returns the maximum total assets in underlying oracle assets
     * @return The maximum total assets limit
     */
    function maxTotalAssetsInUnderlying() external view returns (uint256);

    /**
     * @notice Returns the oracle connector address
     * @return The address of the oracle connector
     */
    function oracleConnector() external view returns (address);

    /**
     * @notice Returns the lending protocol connector address
     * @return The address of the lending connector
     */
    function lendingConnector() external view returns (address);

    /**
     * @notice Returns the fee collector address
     * @return The address of the fee collector
     */
    function feeCollector() external view returns (address);

    /**
     * @notice Returns the last seen token price
     * @return The last seen token price
     */
    function lastSeenTokenPrice() external view returns (uint256);

    /**
     * @notice Returns the base total supply
     * @return The base total supply
     */
    function baseTotalSupply() external view returns (uint256);

    // ========================================
    // ADMINISTRATION FUNCTIONS
    // ========================================

    /**
     * @notice Sets the protocol's new target LTV
     * @param dividend The new target LTV numerator
     * @param divider The new target LTV denominator
     */
    function setTargetLtv(uint16 dividend, uint16 divider) external;

    /**
     * @notice Sets the protocol's new maximum safe LTV
     * @param dividend The new maximum safe LTV numerator
     * @param divider The new maximum safe LTV denominator
     */
    function setMaxSafeLtv(uint16 dividend, uint16 divider) external;

    /**
     * @notice Sets the protocol's new minimum profit LTV
     * @param dividend The new minimum profit LTV numerator
     * @param divider The new minimum profit LTV denominator
     */
    function setMinProfitLtv(uint16 dividend, uint16 divider) external;

    /**
     * @notice Sets the protocol's new fee collector
     * @param _feeCollector The new fee collector address
     */
    function setFeeCollector(address _feeCollector) external;

    /**
     * @notice Sets the lending protocol connector address
     * @param _lendingConnector The new lending connector address
     * @param lendingConnectorData Additional data for the lending connector
     */
    function setLendingConnector(address _lendingConnector, bytes memory lendingConnectorData) external;

    /**
     * @notice Sets the protocol's maximum growth fee
     * @param dividend The maximum growth fee numerator
     * @param divider The maximum growth fee denominator
     */
    function setMaxGrowthFee(uint16 dividend, uint16 divider) external;

    /**
     * @notice Sets the protocol's maximum total assets in underlying oracle assets
     * @param _maxTotalAssetsInUnderlying The new maximum total assets limit
     */
    function setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying) external;

    /**
     * @notice Sets the maximum deleverage fee
     * @param dividend The maximum deleverage fee numerator
     * @param divider The maximum deleverage fee denominator
     */
    function setMaxDeleverageFee(uint16 dividend, uint16 divider) external;

    /**
     * @notice Sets the oracle connector address
     * @param _oracleConnector The new oracle connector address
     * @param oracleConnectorData Additional data for the oracle connector
     */
    function setOracleConnector(address _oracleConnector, bytes memory oracleConnectorData) external;

    /**
     * @notice Sets the slippage connector address
     * @param _slippageConnector The new slippage connector address
     * @param slippageConnectorData Additional data for the slippage connector
     */
    function setSlippageConnector(address _slippageConnector, bytes memory slippageConnectorData) external;

    /**
     * @notice Sets the vault balance as lending connector
     * @param _vaultBalanceAsLendingConnector The new vault balance connector address
     * @param vaultBalanceAsLendingConnectorGetterData Additional data for the connector
     */
    function setVaultBalanceAsLendingConnector(
        address _vaultBalanceAsLendingConnector,
        bytes memory vaultBalanceAsLendingConnectorGetterData
    ) external;

    /**
     * @notice Sweeps tokens from the protocol to the owner,
     * needed to withdraw tokens which were sent to the protocol by mistake.
     * @param token The token to sweep
     * @param amount The amount of tokens to sweep
     */
    function sweep(address token, uint256 amount) external;

    /**
     * @notice Sets whether deposits are disabled
     * @param value True to disable deposits, false to enable
     */
    function setIsDepositDisabled(bool value) external;

    /**
     * @notice Sets whether withdrawals are disabled
     * @param value True to disable withdrawals, false to enable
     */
    function setIsWithdrawDisabled(bool value) external;

    /**
     * @notice Sets whether whitelist is activated
     * @param activate True to activate whitelist, false to deactivate
     */
    function setIsWhitelistActivated(bool activate) external;

    /**
     * @notice Sets the whitelist registry address
     * @param value The new whitelist registry address
     */
    function setWhitelistRegistry(address value) external;

    // ========================================
    // ACCESS CONTROL FUNCTIONS
    // ========================================

    /**
     * @notice Returns the address of the current owner
     * @return The current owner address
     */
    function owner() external view returns (address);

    /**
     * @notice Transfers contract ownership to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Renounces ownership of the contract
     */
    function renounceOwnership() external;

    /**
     * @notice Returns the governor address
     * @return The governor address
     */
    function governor() external view returns (address);

    /**
     * @notice Updates the governor address
     * @param newGovernor The new governor address
     */
    function updateGovernor(address newGovernor) external;

    /**
     * @notice Returns the guardian address
     * @return The guardian address
     */
    function guardian() external view returns (address);

    /**
     * @notice Updates the guardian address
     * @param newGuardian The new guardian address
     */
    function updateGuardian(address newGuardian) external;

    /**
     * @notice Returns the emergency deleverager address
     * @return The emergency deleverager address
     */
    function emergencyDeleverager() external view returns (address);

    /**
     * @notice Updates the emergency deleverager address
     * @param newEmergencyDeleverager The new emergency deleverager address
     */
    function updateEmergencyDeleverager(address newEmergencyDeleverager) external;

    // ========================================
    // UTILITY AND INTERNAL FUNCTIONS
    // ========================================

    /**
     * @notice Initializes the contract with initial state data
     * @param stateInitData The initial state data
     */
    function initialize(StateInitData memory stateInitData) external;

    /**
     * @notice Returns the modules contract address
     * @return The modules contract address
     */
    // forge-lint: disable-next-line(mixed-case-function)
    function MODULES() external view returns (IModules);

    /**
     * @notice Returns whether a function is disabled
     * @param signature The function signature to check
     * @return True if the function is disabled
     */
    function _isFunctionDisabled(bytes4 signature) external view returns (bool);

    /**
     * @notice Allows disabling/enabling specific functions
     * @param signatures Array of function signatures to modify
     * @param isDisabled Whether to disable or enable the functions
     */
    function allowDisableFunctions(bytes4[] memory signatures, bool isDisabled) external;

    /**
     * @notice Returns the boolean slot value
     * @return The boolean slot value
     */
    function boolSlot() external view returns (uint256);

    /**
     * @notice Returns whether deposits are disabled
     * @return True if deposits are disabled
     */
    function isDepositDisabled() external view returns (bool);

    /**
     * @notice Returns whether the protocol is paused
     * @return True if the protocol is paused
     */
    function isProtocolPaused() external view returns (bool);

    /**
     * @notice Returns whether withdrawals are disabled
     * @return True if withdrawals are disabled
     */
    function isWithdrawDisabled() external view returns (bool);

    /**
     * @notice Returns whether whitelist is activated
     * @return True if whitelist is activated
     */
    function isWhitelistActivated() external view returns (bool);

    /**
     * @notice Returns whether the vault is deleveraged
     * @return True if the vault is deleveraged
     */
    function isVaultDeleveraged() external view returns (bool);

    /**
     * @notice Returns the whitelist registry address
     * @return The whitelist registry address
     */
    function whitelistRegistry() external view returns (address);

    /**
     * @notice Returns the slippage connector address
     * @return The slippage connector address
     */
    function slippageConnector() external view returns (address);

    /**
     * @notice Returns the vault balance as lending connector address
     * @return The vault balance connector address
     */
    function vaultBalanceAsLendingConnector() external view returns (address);

    /**
     * @notice Returns the lending connector getter data
     * @return The lending connector getter data
     */
    function lendingConnectorGetterData() external view returns (bytes memory);

    /**
     * @notice Returns the oracle connector getter data
     * @return The oracle connector getter data
     */
    function oracleConnectorGetterData() external view returns (bytes memory);

    /**
     * @notice Returns the slippage connector getter data
     * @return The slippage connector getter data
     */
    function slippageConnectorGetterData() external view returns (bytes memory);

    /**
     * @notice Returns the vault balance connector getter data
     * @return The vault balance connector getter data
     */
    function vaultBalanceAsLendingConnectorGetterData() external view returns (bytes memory);

    /**
     * @notice Returns the maximum growth fee (numerator)
     * @return The maximum growth fee numerator
     */
    function maxGrowthFeeDividend() external view returns (uint16);

    /**
     * @notice Returns the maximum growth fee (denominator)
     * @return The maximum growth fee denominator
     */
    function maxGrowthFeeDivider() external view returns (uint16);

    /**
     * @notice Returns the maximum deleverage fee (numerator)
     * @return The maximum deleverage fee numerator
     */
    function maxDeleverageFeeDividend() external view returns (uint16);

    /**
     * @notice Returns the maximum deleverage fee (denominator)
     * @return The maximum deleverage fee denominator
     */
    function maxDeleverageFeeDivider() external view returns (uint16);

    /**
     * @notice Returns the get current lending connector address.
     * It's either connector to lending protocol or vault balance as lending connector
     * for deleveraged vault.
     * @return The get lending connector address
     */
    function getLendingConnector() external view returns (address);

    /**
     * @notice Executes deleverage and withdraw operation
     * @param closeAmountBorrow The amount of borrow to close
     * @param deleverageFeeDividend The deleverage fee numerator
     * @param deleverageFeeDivider The deleverage fee denominator
     */
    function deleverageAndWithdraw(uint256 closeAmountBorrow, uint16 deleverageFeeDividend, uint16 deleverageFeeDivider)
        external;

    // ========================================
    // EVENTS
    // ========================================

    /**
     * @notice Emitted when the contract is initialized
     * @param version The initialization version
     */
    event Initialized(uint64 version);

    /**
     * @notice Emitted when ownership is transferred
     * @param previousOwner The address of the previous owner
     * @param newOwner The address of the new owner
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ========================================
    // ERRORS
    // ========================================

    /**
     * @notice Error thrown when initialization is invalid
     */
    error InvalidInitialization();

    /**
     * @notice Error thrown when not initializing
     */
    error NotInitializing();

    /**
     * @notice Error thrown when the owner is invalid
     * @param owner The invalid owner address
     */
    error OwnableInvalidOwner(address owner);

    /**
     * @notice Error thrown when an account is unauthorized
     * @param account The unauthorized account address
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @notice Error thrown when there's a reentrant call
     */
    error ReentrancyGuardReentrantCall();
}
