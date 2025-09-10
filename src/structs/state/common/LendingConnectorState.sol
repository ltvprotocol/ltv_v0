// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title LendingConnectorState
 * @notice struct containing state related to lending connector
 */
struct LendingConnectorState {
    uint8 boolSlot;
    address lendingConnector;
    address vaultBalanceAsLendingConnector;
}
