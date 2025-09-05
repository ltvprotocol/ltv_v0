// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title RevertWithDataIfNeeded
 * @notice contract contains functionality to rethrow revert error after delegatecall
 */
abstract contract RevertWithDataIfNeeded {
    /**
     * @dev rethrows revert error after delegatecall
     */
    function revertWithDataIfNeeded(bool condition, bytes memory data) internal pure {
        if (!condition) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }
    }
}
