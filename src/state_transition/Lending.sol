// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../states/LTVState.sol';

abstract contract Lending is LTVState {
    function borrow(uint256 assets) internal {
        (bool isSuccess, ) = address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.borrow, (assets)));
        require(isSuccess);
    }

    function repay(uint256 assets) internal {
        (bool isSuccess, ) = address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.repay, (assets)));
        require(isSuccess);
    }

    function supply(uint256 assets) internal {
        (bool isSuccess, ) = address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.supply, (assets)));
        require(isSuccess);
    }

    function withdraw(uint256 assets) internal {
        (bool isSuccess, ) = address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.withdraw, (assets)));
        require(isSuccess);
    }
}