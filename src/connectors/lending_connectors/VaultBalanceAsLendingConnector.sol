// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {ILendingConnector} from "src/interfaces/ILendingConnector.sol";
import {LTVState} from "../../states/LTVState.sol";

contract VaultBalanceAsLendingConnector is LTVState, ILendingConnector {
    error UnexpectedBorrowCall();
    error UnexpectedRepayCall();
    error UnexpectedSupplyCall();

    function getRealCollateralAssets(bool, bytes calldata) external view returns (uint256) {
        return collateralToken.balanceOf(msg.sender);
    }

    function getRealBorrowAssets(bool, bytes calldata) external view returns (uint256) {
        return borrowToken.balanceOf(msg.sender);
    }

    function withdraw(uint256) external {}

    function borrow(uint256) external pure {
        revert UnexpectedBorrowCall();
    }

    function repay(uint256) external pure {
        revert UnexpectedRepayCall();
    }

    function supply(uint256) external pure {
        revert UnexpectedSupplyCall();
    }

    function initializeLendingConnectorData(bytes memory) external pure {}
}
