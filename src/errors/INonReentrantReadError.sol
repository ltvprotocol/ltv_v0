// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title INonReentrantReadError
 * @notice Interface defining all custom errors used in non-reentrant read functions
 */
interface INonReentrantReadError {
    error NonReentrantRead();

    /**
     * @notice Error thrown when the function is called while the reentrancy guard is entered
     * @dev Used when the function is called while the reentrancy guard is already entered
     */
    error ReentrantReadDuringWriteCallError();
}
