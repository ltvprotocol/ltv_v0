# Facades

Facade contracts that provide the public interface and routing logic for the LTV protocol's modular architecture. These contracts act as the bridge between external calls and internal modules. 

## reads/

Read-only facade contracts that handle view and pure function calls.

- **AdministrationRead.sol** - Administration state queries and configuration reads
- **AuctionRead.sol** - Auction system state and preview functions
- **BorrowVaultRead.sol** - Borrow vault state and balance queries
- **CollateralVaultRead.sol** - Collateral vault state and balance queries
- **ERC20Read.sol** - ERC-20 token state and balance queries
- **LowLevelRebalanceRead.sol** - Rebalancing state and calculation queries

## writes/

Write facade contracts that handle state-changing function calls.

- **AdministrationWrite.sol** - Administration configuration and parameter updates
- **AuctionWrite.sol** - Auction execution and liquidation functions
- **BorrowVaultWrite.sol** - Borrow vault operations and debt management
- **CollateralVaultWrite.sol** - Collateral vault operations and asset management
- **ERC20Write.sol** - ERC-20 token operations and transfers
- **InitializeWrite.sol** - Protocol initialization and setup functions
- **LowLevelRebalanceWrite.sol** - Core rebalancing operations
---
- **CommonWrite.sol** - Shared write functionality and utilities