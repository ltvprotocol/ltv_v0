// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title ISlippageConnectorErrors
 * @notice Interface defining custom errors for slippage parameters validation
 */
interface IConstantSlippageConnectorErrors {
    /**
     * @notice Error thrown when Slippage Connector borrow slippage value is invalid
     */
    error InvalidBorrowSlippageValue();

    /**
     * @notice Error thrown when Slippage Connector collateral slippage value is invalid
     */
    error InvalidCollateralSlippageValue();
}
