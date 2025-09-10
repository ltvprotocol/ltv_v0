// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";

/**
 * @title CommonWrite
 * @notice This contract contains all the common write functions for the LTV protocol.
 * It delegates calls to the corresponding module. It's expected that facade write function
 * and module write function have the same signature and return data. Implemented function will
 * fail if delegate call fails or if supplied implementation is not smart contract..
 */
abstract contract CommonWrite {
    /**
     * @dev delegates call to the corresponding module
     */
    function _delegate(address implementation, bytes memory encodedParams) internal {
        (bool success, bytes memory returndata) = implementation.delegatecall(bytes.concat(msg.sig, encodedParams));

        if (success) {
            if (returndata.length == 0 && implementation.code.length == 0) {
                revert IAdministrationErrors.EOADelegateCall();
            }

            assembly {
                return(add(returndata, 32), mload(returndata))
            }
        }

        assembly {
            revert(add(returndata, 32), mload(returndata))
        }
    }
}
