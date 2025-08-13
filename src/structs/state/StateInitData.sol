// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/interfaces/ILendingConnector.sol";
import "src/interfaces/IOracleConnector.sol";
import "src/interfaces/ISlippageProvider.sol";
import "src/interfaces/IModules.sol";

struct StateInitData {
    string name;
    string symbol;
    uint8 decimals;
    address collateralToken;
    address borrowToken;
    address feeCollector;
    uint16 maxSafeLTVDividend;
    uint16 maxSafeLTVDivider;
    uint16 minProfitLTVDividend;
    uint16 minProfitLTVDivider;
    uint16 targetLTVDividend;
    uint16 targetLTVDivider;
    ILendingConnector lendingConnector;
    IOracleConnector oracleConnector;
    uint16 maxGrowthFeeDividend;
    uint16 maxGrowthFeeDivider;
    uint256 maxTotalAssetsInUnderlying;
    ISlippageProvider slippageProvider;
    uint16 maxDeleverageFeeDividend;
    uint16 maxDeleverageFeeDivider;
    ILendingConnector vaultBalanceAsLendingConnector;
    address owner;
    address guardian;
    address governor;
    address emergencyDeleverager;
    uint24 auctionDuration;
    bytes lendingConnectorData;
}
