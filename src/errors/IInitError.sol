// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IInitError {
    error FaildedToInitializeLendingConnector(bytes data);
    error FaildedToInitializeOracleConnector(bytes data);
    error FaildedToInitializeSlippageProvider(bytes data);
}
