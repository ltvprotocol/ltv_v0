# Elements

Core infrastructure contracts that implement the LTV protocol's modular architecture and upgradability system. These elements coordinate and orchestrate the protocol's functionality through a beacon proxy pattern with modular design.

## Architecture Overview

The LTV protocol uses a **modules-facade architecture** to support upgradability while avoiding the 24,576-byte contract size limit. The system consists of:

- **Beacon Proxy Pattern**: Enables atomic upgrades across multiple vaults
- **Facade Contract**: Provides simplified ABI interface with routing logic
- **Modulares**: Business logic split across specialized modules
- **Connector System**: Adapters for external protocol integrations

## Core Contracts

### LTV.sol

The main facade contract that serves as the public interface for the entire LTV protocol.

### ModulesProvider.sol

Registry contract that manages and provides access to all protocol modules.

**Module Slots:**
- `BORROW_VAULT_MODULE` - Borrow vault operations
- `COLLATERAL_VAULT_MODULE` - Collateral vault operations  
- `LOW_LEVEL_REBALANCE_MODULE` - Core rebalancing logic
- `AUCTION_MODULE` - Auction system functionality
- `ERC20_MODULE` - Token standard operations
- `ADMINISTRATION_MODULE` - Protocol administration
- `INITIALIZE_MODULE` - Initialization procedures

### WhitelistRegistry.sol
Manages address whitelisting for protocol access control.

## Modules Directory

- **AdministrationModule.sol** - Protocol administration and access control operations
- **AuctionModule.sol** - Auction system for liquidations and rebalancing
- **BorrowVaultModule.sol** - Borrow vault operations and debt management
- **CollateralVaultModule.sol** - Collateral vault operations and asset management
- **ERC20Module.sol** - ERC-20 token standard compliance and operations
- **InitializeModule.sol** - Protocol initialization and setup procedures
- **LowLevelRebalanceModule.sol** - Core rebalancing logic with gas optimization