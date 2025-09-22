# Leveraged Tokenized Vault v0

[![License: BUSL-1.1](https://img.shields.io/badge/License-BUSL--1.1-blue.svg)](https://opensource.org/licenses/BUSL-1.1)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.28-blue.svg)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg)](https://getfoundry.sh/)

> **⚠️ SECURITY WARNING**  
> This protocol has **NOT** been audited and may contain critical vulnerabilities.  

## Overview

The LTV Protocol is a revolutionary **Curatorless Leveraged Tokenized Vault** that maintains a constant target Loan-To-Value (LTV) ratio without requiring a central curator. Built on the foundation of two interconnected EIP-4626 vaults, it enables users to deposit and withdraw funds while receiving tokenized shares representing their leveraged positions.

The protocol's core innovation lies in its **auction-based stimulus system** that incentivizes users to participate in rebalancing actions through rewards or fees. This mechanism ensures alignment with the target LTV while providing basic MEV protection against frontrunning.

## Original paper

The original paper is available here:

[LTV: Curatorless Leveraged Tokenized Vault with a Constant Target Loan-To-Value Ratio](https://github.com/ltvprotocol/papers/blob/main/LTV_Curatorless_Leveraged_Tokenized_Vault_with_a_Constant_Target_Loan-To-Value_Ratio.pdf)

#### Abstract:

The proposed system is a Curatorless Leveraged Tokenized Vault (LTV) with a Constant Target Loan-To-Value (LTV) ratio. This vault operates without a central curator and allows users to deposit and withdraw funds while receiving tokenized shares representing their holdings. The architec- ture is based on two interconnected EIP4626 vaults. To ensure alignment with the target LTV, an auction-based stimulus system is employed, which incentivizes users to participate in rebalancing actions through rewards or fees. This approach also integrates basic level of MEV protection to guard against frontrunning and maintain system integrity.

## Supported Lending Protocols

The protocol currently supports integration with major DeFi lending protocols:

### Aave V3
- **Lending Connector**: `AaveV3Connector`
- **Oracle Connector**: `AaveV3OracleConnector`

### Morpho Blue
- **Lending Connector**: `MorphoConnector` 
- **Oracle Connector**: `MorphoOracleConnector`

### HodlMyBeer Lending with SpookyOracle (Testnet protocols)
- **Lending Connector**: `HodlLendingConnector`
- **Oracle Connector**: `SpookyOracleConnector`

## Build and Test

```bash
forge build
forge test -vvv --no-match-path "test/integration/**"
```

## License

This project is licensed under the Business Source License 1.1 (BUSL-1.1). See the [LICENSE](LICENSE) file for details.

## Links

- **Website**: [LTV](https://ltv.finance)
- **Repository**: [GitHub Repository](https://github.com/ltvprotocol/ltv_v0)
- **Documentation**: [Protocol Documentation](https://docs.ltv.finance)
- **Twitter**: [@ltvprotocol](https://x.com/ltvprotocol)
