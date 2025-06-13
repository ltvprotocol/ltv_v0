// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

abstract contract CommonWrite {
    function _delegate(address implementation, bytes memory encodedParams) internal {
        require(implementation != address(0));
        (bool result, bytes memory data) = implementation.delegatecall(bytes.concat(msg.sig, encodedParams));

        assembly {
            switch result
            case 0 { revert(add(data, 32), mload(data)) }
            default { return(add(data, 32), mload(data)) }
        }
    }
}
