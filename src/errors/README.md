# Errors

The `errors` folder contains interface definitions for all custom errors used throughout the **LTV Protocol**. These interfaces provide a centralized, type-safe way to define and use custom errors across the protocol.

## Error Categories

### 1. Administration Errors (`IAdministrationErrors.sol`)

Administrative operations, access control, and configuration validation errors.

#### LTV Parameter Validation
- **`InvalidLTVSet`**: LTV parameters don't satisfy required relationships
- **`UnexpectedmaxSafeLtv`**: Max safe LTV doesn't meet expected constraints
- **`UnexpectedminProfitLtv`**: Min profit LTV doesn't meet expected constraints
- **`UnexpectedtargetLtv`**: Target LTV doesn't meet expected constraints

#### Access Control
- **`OnlyGovernorInvalidCaller`**: Function called by non-governor account
- **`OnlyGuardianInvalidCaller`**: Function called by non-guardian account
- **`OnlyEmergencyDeleveragerInvalidCaller`**: Function called by non-emergency deleverager

#### Configuration Validation
- **`ZeroFeeCollector`**: Attempting to set zero address as fee collector
- **`ZeroSlippageConnector`**: Attempting to set zero address as slippage connector
- **`ZeroModulesProvider`**: Attempting to set zero address as modules provider

#### Fee Management
- **`InvalidMaxDeleverageFee`**: Deleverage fee parameters don't meet constraints
- **`ExceedsMaxDeleverageFee`**: Deleverage fee exceeds maximum allowed
- **`InvalidMaxGrowthFee`**: Growth fee parameters don't meet constraints

#### State Management
- **`DepositIsDisabled`**: Deposit functionality is disabled
- **`WithdrawIsDisabled`**: Withdraw functionality is disabled
- **`FunctionStopped`**: Specific function is stopped/disabled
- **`VaultAlreadyDeleveraged`**: Attempting to deleverage already deleveraged vault

#### Whitelist Management
- **`ReceiverNotWhitelisted`**: Attempting to send assets to non-whitelisted receiver
- **`WhitelistRegistryNotSet`**: Whitelist registry is not configured
- **`WhitelistIsActivated`**: Whitelist is already activated

#### Connector Configuration
- **`FailedToSetLendingConnector`**: Setting lending connector failed
- **`FailedToSetOracleConnector`**: Setting oracle connector failed
- **`FailedToSetSlippageConnector`**: Setting slippage connector failed
- **`FailedToSetVaultBalanceAsLendingConnector`**: Setting vault balance connector failed

### 2. Vault Errors (`IVaultErrors.sol`)

Vault operations, deposit/withdraw limits, and data validation errors.

#### Delta Data Validation
- **`DeltaSharesAndDeltaRealBorrowUnexpectedError`**: Unexpected error in share/borrow delta data
- **`DeltaSharesAndDeltaRealCollateralUnexpectedError`**: Unexpected error in share/collateral delta data
- **`DeltaRealBorrowAndDeltaRealCollateralUnexpectedError`**: Unexpected error in borrow/collateral delta data

#### Deposit/Withdraw Limits
- **`ExceedsMaxDeposit`**: Deposit amount exceeds maximum allowed
- **`ExceedsMaxWithdraw`**: Withdrawal amount exceeds maximum allowed
- **`ExceedsMaxMint`**: Mint amount exceeds maximum allowed
- **`ExceedsMaxRedeem`**: Redeem amount exceeds maximum allowed

#### Collateral Limits
- **`ExceedsMaxDepositCollateral`**: Collateral deposit amount exceeds maximum allowed
- **`ExceedsMaxWithdrawCollateral`**: Collateral withdrawal amount exceeds maximum allowed
- **`ExceedsMaxMintCollateral`**: Collateral mint amount exceeds maximum allowed
- **`ExceedsMaxRedeemCollateral`**: Collateral redeem amount exceeds maximum allowed

### 3. Auction Errors (`IAuctionErrors.sol`)

Auction operations and validation errors.

#### Auction Creation
- **`NoAuctionForProvidedDeltaFutureCollateral`**: No auction can be created for provided collateral delta
- **`NoAuctionForProvidedDeltaFutureBorrow`**: No auction can be created for provided borrow delta

#### Delta Validation
- **`UnexpectedDeltaUserBorrowAssets`**: Delta user borrow assets doesn't match calculated value
- **`UnexpectedDeltaUserCollateralAssets`**: Delta user collateral assets doesn't match calculated value

### 4. Low-Level Rebalance Errors (`ILowLevelRebalanceErrors.sol`)

Low-level rebalancing operation limits and validation errors.

#### Rebalance Limits
- **`ExceedsLowLevelRebalanceMaxDeltaCollateral`**: Collateral delta exceeds maximum allowed
- **`ExceedsLowLevelRebalanceMaxDeltaBorrow`**: Borrow delta exceeds maximum allowed
- **`ExceedsLowLevelRebalanceMaxDeltaShares`**: Shares delta exceeds maximum allowed

#### Configuration Issues
- **`ZeroTargetLtvDisablesBorrow`**: Target LTV is zero, disabling borrow functionality

### 5. ERC20 Errors (`IERC20Errors.sol`)

Standard ERC20 operation errors.

#### Transfer Validation
- **`TransferToZeroAddress`**: Attempting to transfer to zero address
- **`ERC20InsufficientAllowance`**: Insufficient allowance for transfer operation