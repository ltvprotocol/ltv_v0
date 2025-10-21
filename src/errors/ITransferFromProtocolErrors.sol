// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title ITransferFromProtocolErrors
 * @notice Interface defining errors which occur during transfering
 * borrow or collateral tokens to zero address
 */
interface ITransferFromProtocolErrors {
    /**
     * @notice Error thrown when trying to transfer borrow tokens to zero address
     */
    error TransferBorrowTokenToZeroAddress();

    /**
     * @notice Error thrown when trying to transfer collateral tokens to zero address
     */
    error TransferCollateralTokenToZeroAddress();
}
