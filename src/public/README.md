# Public

Public function implementations that form the core business logic of the LTV protocol. These contracts implement the actual functionality that users interact with.

## Operations

### Read Operations (View Functions)
Located in `read/` subdirectories, these contracts implement pure and view functions.

### Write Operations (State Changes)
Located in `write/` subdirectories, these contracts implement state-changing functions.

## Modules

The protocol is organized into **6 specialized modules**, with **2 main vault modules**:

### 1. **BorrowVaultModule** (Vault Module)
Manages debt token operations and borrow vault functionality.

### 2. **CollateralVaultModule** (Vault Module)
Handles collateral token operations and collateral vault functionality.

### 3. **AuctionModule**
Implements the auction system for rebalancing.

### 4. **ERC20Module**
Provides ERC-20 token standard compliance.

### 5. **LowLevelRebalanceModule**
Contains low level rebalancing logic with interaction with 3 tokens.

### 6. **AdministrationModule**
Handles protocol administration and access control.