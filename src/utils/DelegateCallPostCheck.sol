// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IDelegateCallError} from "src/errors/IDelegateCallError.sol";
/**
 * @title DelegateCallPostCheck
 * @notice contract contains functionality to rethrow revert error after delegatecall
 */

abstract contract DelegateCallPostCheck is IDelegateCallError {
    /**
     * @dev rethrows revert error after delegatecall
     */
    function delegateCallPostCheck(address target, bool isSuccess, bytes memory data) internal view {
        if (!isSuccess) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }

        require(data.length != 0 || target.code.length != 0, EOADelegateCall());
    }
}
