// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../errors/IAdministrationErrors.sol";

abstract contract CommonWrite {
    function _delegate(address implementation, bytes memory encodedParams) internal {
        if (implementation == address(0)) {
            revert IAdministrationErrors.ZeroDataRevert();
        }
        (bool result, bytes memory data) = implementation.delegatecall(bytes.concat(msg.sig, encodedParams));

        assembly {
            switch result
            case 0 { revert(add(data, 32), mload(data)) }
            default { return(add(data, 32), mload(data)) }
        }
    }
}
