// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IInitError {
    error FaildedToInitializeWithCallData(bytes callData);
    error InvalidVaultBalanceAsLendingConnector(address vaultBalanceAsLendingConnector);
}
