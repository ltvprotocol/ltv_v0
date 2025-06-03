// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/state_reader/GetLendingConnectorReader.sol";

abstract contract Lending is GetLendingConnectorReader {
    function revertWithDataIfNeeded(bool isSuccess, bytes memory data) internal pure {
        if (!isSuccess) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }
    }

    function borrow(uint256 assets) internal {
        (bool isSuccess, bytes memory data) =
            address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.borrow, (assets)));
        revertWithDataIfNeeded(isSuccess, data);
    }

    function repay(uint256 assets) internal {
        (bool isSuccess, bytes memory data) =
            address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.repay, (assets)));
        revertWithDataIfNeeded(isSuccess, data);
    }

    function supply(uint256 assets) internal {
        (bool isSuccess, bytes memory data) =
            address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.supply, (assets)));
        revertWithDataIfNeeded(isSuccess, data);
    }

    function withdraw(uint256 assets) internal {
        (bool isSuccess, bytes memory data) =
            address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.withdraw, (assets)));
        revertWithDataIfNeeded(isSuccess, data);
    }
}
