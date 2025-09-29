# Connectors - Interfaces for Integration

The LTV protocol uses connectors to stay modular and adaptable, allowing seamless integration. This design ensures that the core logic stay separated even as the ecosystem evolves or new protocols emerge.

## Architecture Overview

The connector system follows a modular design pattern where each connector type implements a standardized interface. This allows the core LTV protocol to remain protocol-agnostic while supporting multiple external integrations.

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   LTV Protocol  │────│    Connectors    │────│ External Systems│
│   (Core Logic)  │    │   (Interfaces)   │    │ (Aave, Morpho,  │
│                 │    │                  │    │  Chainlink, etc)│
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Connector Types

### 1. Lending Protocol Connector

The Lending Protocol Connector determines how the vault interacts with external lending platforms to deposit collateral and borrow assets.

#### Implementations

| Connector | Protocol | Description |
|-----------|----------|-------------|
| `AaveV3Connector` | Aave V3 | Full integration with Aave V3 Pool for supply/borrow/repay operations |
| `MorphoConnector` | Morpho Blue | Market-based lending with custom parameters and oracle integration |

### 2. Oracle Connector

The Oracle Connector handles how the vault obtains and interprets price data for assets like LSTs or borrow tokens.

#### Implementations

| Connector | Oracle Source | Description |
|-----------|---------------|-------------|
| `AaveV3OracleConnector` | Aave V3 Oracle | Uses Aave's built-in price oracle for asset pricing |
| `MorphoOracleConnector` | Morpho Oracle | Integrates with Morpho's oracle system for market-based pricing |


### 3. Slippage Connector

The Slippage Connector in the LTV protocol framework is a mechanism that governs how price slippage is accounted for during operations like rebalancing and auctions.

#### Implementations

| Connector | Type | Description |
|-----------|------|-------------|
| `ConstantSlippageConnector` | Fixed Slippage | Uses predefined slippage values for consistent behavior |
