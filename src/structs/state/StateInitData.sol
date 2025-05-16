// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/interfaces/ILendingConnector.sol';
import 'src/interfaces/IOracleConnector.sol';
import 'src/interfaces/ISlippageProvider.sol';
import 'src/interfaces/IModules.sol';

struct StateInitData {
    string name;
    string symbol;
    uint8 decimals;
    address collateralToken;
    address borrowToken;
    address feeCollector;
    uint128 maxSafeLTV;
    uint128 minProfitLTV;
    uint128 targetLTV;
    ILendingConnector lendingConnector;
    IOracleConnector oracleConnector;
    uint256 maxGrowthFee;
    uint256 maxTotalAssetsInUnderlying;
    ISlippageProvider slippageProvider;
    uint256 maxDeleverageFee;
    ILendingConnector vaultBalanceAsLendingConnector;
    IModules modules;
    address owner;
    address guardian;
    address governor;
    address emergencyDeleverager;
    bytes callData;
}
