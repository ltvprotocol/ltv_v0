// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/state_reader/GetLendingConnectorReader.sol";
import "src/errors/ILendingErrors.sol";

abstract contract Lending is GetLendingConnectorReader, ILendingErrors {
    function borrow(uint256 assets) internal {
        (bool isSuccess,) =
            address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.borrow, (assets)));
        if (!isSuccess) revert BorrowFailed(address(this), address(getLendingConnector()), assets);
    }

    function repay(uint256 assets) internal {
        (bool isSuccess,) =
            address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.repay, (assets)));
        if (!isSuccess) revert RepayFailed(address(this), address(getLendingConnector()), assets);
    }

    function supply(uint256 assets) internal {
        (bool isSuccess,) =
            address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.supply, (assets)));
        if (!isSuccess) revert SupplyFailed(address(this), address(getLendingConnector()), assets);
    }

    function withdraw(uint256 assets) internal {
        (bool isSuccess,) =
            address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.withdraw, (assets)));
        if (!isSuccess) revert WithdrawFailed(address(this), address(getLendingConnector()), assets);
    }
}
