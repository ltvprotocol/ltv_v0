# Math

Core mathematical libraries and abstractions that implement the LTV protocol's complex financial calculations. These calculations are derived from the LTV protocol paper and handle all the mathematical operations required for vault operations, auctions, rebalancing, and fee calculations.

## Architecture Overview

The math system is organized into two main categories:

### 1. **Abstracts** (`abstracts/`)
Organised as abstract contract.

### 2. **Libraries** (`libraries/`)
Organised as extarnal libraries contract.

## Abstracts

### Core Abstracts

#### **AuctionStateToData.sol**
Converts auction state to data needed for auction calculations.

#### **BoolReader.sol**
Provides common functionality for reading boolean vault states.

#### **MaxGrowthFee.sol**
Handles maximum growth fee calculations to ensure fee collector receives appropriate compensation.

#### **Vault.sol**
Common functionality for all max vault functions.

#### **VaultCollateral.sol**
Common functionality for all max collateral vault functions.

### State-to-Data Transformations

#### **Max Operations**
- **MaxDepositMintStateToData.sol** - Converts state to data for max deposit/mint calculations
- **MaxDepositMintCollateralStateToData.sol** - Converts state to data for max deposit/mint collateral calculations
- **MaxWithdrawRedeemStateToData.sol** - Converts state to data for max withdraw/redeem calculations
- **MaxWithdrawRedeemCollateralStateToData.sol** - Converts state to data for max withdraw/redeem collateral calculations

#### **Preview Operations**
- **PreviewDepositStateToPreviewDepositData.sol** - Converts preview deposit state to data
- **PreviewDepositVaultStateToCollateralData.sol** - Converts preview deposit vault state to collateral data
- **PreviewWithdrawStateToPreviewWithdrawData.sol** - Converts preview withdraw state to data
- **PreviewWithdrawVaultStateToCollateralData.sol** - Converts preview withdraw vault state to collateral data
- **PreviewLowLevelRebalanceStateToData.sol** - Converts preview low-level rebalance state to data

#### **Fee Operations**
- **MaxGrowthFeeStateToConvertCollateralData.sol** - Converts max growth fee state to convert collateral data

## Libraries

### Core Mathematical Libraries

#### **MulDiv.sol**
Precision multiplication and division operations with proper rounding.
- **UMulDiv** - Unsigned integer multiplication/division with rounding control
- **SMulDiv** - Signed integer multiplication/division with rounding control

#### **CommonMath.sol**
Common mathematical utilities and conversions.

#### **CasesOperator.sol**
Generates mathematical cases for different operation scenarios.

### Vault Operation Libraries

#### **DepositWithdraw.sol**
Calculates state transitions for deposit and withdraw operations.

#### **MintRedeem.sol**
Calculates state transitions for mint and redeem operations.

#### **LowLevelRebalanceMath.sol**
Rebalancing logic for 3 tokens operations.

### Auction System Libraries

#### **AuctionMath.sol**
Comprehensive auction calculation system.

#### **CommonBorrowCollateral.sol**
Common calculations for borrow and collateral operations.

### Core mathematics (3 fundaments functions)

#### **DeltaSharesAndDeltaRealBorrow.sol**
Calculates deltaFutureBorrow from deltaShares and deltaRealBorrow.

#### **DeltaRealBorrowAndDeltaRealCollateral.sol**
Calculates deltaFutureCollateral from deltaRealBorrow and deltaRealCollateral.

#### **DeltaSharesAndDeltaRealCollateral.sol**
Calculates deltaFutureCollateral from deltaShares and deltaRealCollateral.

#### **NextStep.sol**
Calculates next state transitions for the protocol.