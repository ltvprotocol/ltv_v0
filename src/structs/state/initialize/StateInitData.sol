// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILendingConnector} from "src/interfaces/connectors/ILendingConnector.sol";
import {IOracleConnector} from "src/interfaces/connectors/IOracleConnector.sol";
import {ISlippageConnector} from "src/interfaces/connectors/ISlippageConnector.sol";

/**
 * @title StateInitData
 * @notice This struct needed for state initialization calculations
 */
struct StateInitData {
    string name;
    string symbol;
    uint8 decimals;
    address collateralToken;
    address borrowToken;
    address feeCollector;
    uint16 maxSafeLtvDividend;
    uint16 maxSafeLtvDivider;
    uint16 minProfitLtvDividend;
    uint16 minProfitLtvDivider;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    ILendingConnector lendingConnector;
    IOracleConnector oracleConnector;
    uint16 maxGrowthFeeDividend;
    uint16 maxGrowthFeeDivider;
    uint256 maxTotalAssetsInUnderlying;
    ISlippageConnector slippageConnector;
    uint16 maxDeleverageFeeDividend;
    uint16 maxDeleverageFeeDivider;
    ILendingConnector vaultBalanceAsLendingConnector;
    address owner;
    address guardian;
    address governor;
    address emergencyDeleverager;
    uint24 auctionDuration;
    bytes lendingConnectorData;
    bytes oracleConnectorData;
    bytes slippageConnectorData;
    bytes vaultBalanceAsLendingConnectorData;
}
