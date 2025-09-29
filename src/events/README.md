# Events

The `events` folder contains interface definitions for all events emitted throughout the **LTV Protocol**. These interfaces provide a centralized, type-safe way to define and emit events across the protocol, enabling transparency and allowing external systems to track protocol activities.

## Event Categories

### 1. Administration Events (`IAdministrationEvents.sol`)

Administrative operations, access control updates, parameter modifications, and system configuration changes.

#### Access Control Updates
- **`EmergencyDeleveragerUpdated`**: Emergency deleverager address changed
- **`GuardianUpdated`**: Guardian address changed  
- **`GovernorUpdated`**: Governor address changed

#### LTV Parameter Changes
- **`TargetLtvChanged`**: Target LTV ratio (optimal borrowing ratio) updated
- **`MaxSafeLtvChanged`**: Maximum safe LTV ratio updated
- **`MinProfitLtvChanged`**: Minimum profit LTV ratio updated

#### System Configuration
- **`WhitelistRegistryUpdated`**: Whitelist registry address changed
- **`MaxTotalAssetsInUnderlyingChanged`**: Maximum total assets limit updated
- **`FeeCollectorUpdated`**: Fee collector address changed
- **`ModulesUpdated`**: Modules provider address changed

#### Fee Management
- **`MaxDeleverageFeeChanged`**: Maximum deleverage fee parameters updated
- **`MaxGrowthFeeChanged`**: Maximum growth fee parameters updated

#### Function State Management
- **`IsWhitelistActivatedChanged`**: Whitelist activation status toggled
- **`IsDepositDisabledChanged`**: Deposit functionality enabled/disabled
- **`IsWithdrawDisabledChanged`**: Withdraw functionality enabled/disabled

#### Connector Updates
- **`LendingConnectorUpdated`**: Lending connector address and configuration updated
- **`OracleConnectorUpdated`**: Oracle connector address and configuration updated
- **`SlippageConnectorUpdated`**: Slippage connector address and configuration updated
- **`VaultBalanceAsLendingConnectorUpdated`**: Vault balance connector address updated

### 2. Auction Events (`IAuctionEvent.sol`)

Auction operations and execution tracking.

#### Auction Execution
- **`AuctionExecuted`**: Auction successfully executed with collateral and borrow changes
  - `executor`: Address that executed the auction
  - `deltaRealCollateralAssets`: Change in real collateral assets
  - `deltaRealBorrowAssets`: Change in real borrow assets

### 3. ERC20 Events (`IERC20Events.sol`)

Standard ERC20 token operations and transfers.

#### Token Operations
- **`Transfer`**: Tokens transferred between addresses (also used for mint/burn)
  - `from`: Address sending tokens (zero address for minting)
  - `to`: Address receiving tokens (zero address for burning)
  - `value`: Amount of tokens transferred
- **`Approval`**: Approval granted for token spending
  - `owner`: Address granting approval
  - `spender`: Address being approved
  - `value`: Amount of tokens approved

### 4. ERC4626 Events (`IERC4626Events.sol`)

Vault deposit and withdrawal operations for both borrow and collateral assets.

#### Borrow Asset Operations
- **`Deposit`**: Borrow assets deposited and shares minted
  - `sender`: Address initiating the deposit
  - `owner`: Address receiving the minted shares
  - `assets`: Amount of borrow assets deposited
  - `shares`: Number of shares minted
- **`Withdraw`**: Borrow assets withdrawn and shares burned
  - `sender`: Address initiating the withdrawal
  - `receiver`: Address receiving the withdrawn assets
  - `owner`: Address whose shares are burned
  - `assets`: Amount of borrow assets withdrawn
  - `shares`: Number of shares burned

#### Collateral Asset Operations
- **`DepositCollateral`**: Collateral assets deposited and shares minted
  - `sender`: Address initiating the deposit
  - `owner`: Address receiving the minted shares
  - `collateralAssets`: Amount of collateral assets deposited
  - `shares`: Number of shares minted
- **`WithdrawCollateral`**: Collateral assets withdrawn and shares burned
  - `sender`: Address initiating the withdrawal
  - `receiver`: Address receiving the withdrawn assets
  - `owner`: Address whose shares are burned
  - `collateralAssets`: Amount of collateral assets withdrawn
  - `shares`: Number of shares burned

### 5. Low-Level Rebalance Events (`ILowLevelRebalanceEvent.sol`)

Low-level rebalancing operations and execution tracking.

#### Rebalance Execution
- **`LowLevelRebalanceExecuted`**: Low-level rebalance successfully executed
  - `executor`: Address that executed the rebalance
  - `deltaRealCollateralAsset`: Change in real collateral assets
  - `deltaRealBorrowAssets`: Change in real borrow assets
  - `deltaShares`: Change in shares