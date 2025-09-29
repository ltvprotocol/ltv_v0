# Interfaces

This directory contains all the interface definitions for the LTV (Loan-to-Value) protocol. The interfaces are organized into three main folders and contain three core interface files in the root directory.

#### `connectors/`
Contains interfaces for external protocol connectors that enable the LTV protocol to interact with various DeFi protocols.

#### `reads/`
Contains read-only interface modules.

#### `writes/`
Contains write interface modules that define protocol initialization operations.

#### `ILTV.sol`
The main interface for the entire LTV protocol. This comprehensive interface includes:

- **EIP-4626 Vault Standard Functions** - Standard vault operations (deposit, withdraw, mint, redeem)
- **EIP-4626 Collateral Vault Extension** - Extended collateral vault operations
- **ERC-20 Standard Functions** - Token standard compliance
- **Auction System Functions** - Auction execution and preview functions
- **Low-Level Rebalance Functions** - Core rebalancing operations with gas optimization hints
- **State Querying Functions** - Protocol state and configuration queries
- **Administration Functions** - Protocol configuration and parameter updates
- **Access Control Functions** - Ownership and role management
- **Utility Functions** - Initialization and module management

This interface inherits from multiple error and event interfaces, providing a complete contract specification.

#### 2. `IModules.sol`

Defines the modular architecture and modules provoder interface. Specifying all available modules:

- `auctionModule()` - Auction system module
- `borrowVaultModule()` - Borrow vault operations module
- `collateralVaultModule()` - Collateral vault operations module
- `erc20Module()` - ERC20 token operations module
- `lowLevelRebalanceModule()` - Low-level rebalancing module
- `administrationModule()` - Administration operations module
- `initializeModule()` - Initialization module

#### 3. `IWhitelistRegistry.sol`

Simple interface for whitelist functionality.