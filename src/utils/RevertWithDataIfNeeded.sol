// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

abstract contract RevertWithDataIfNeeded {
    function revertWithDataIfNeeded(bool condition, bytes memory data) internal pure {
        if (!condition) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }
    }
}
