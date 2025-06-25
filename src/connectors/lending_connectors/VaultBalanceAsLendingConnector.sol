// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "forge-std/interfaces/IERC20.sol";
import "../../interfaces/ILendingConnector.sol";

contract VaultBalanceAsLendingConnector is ILendingConnector {
    IERC20 public immutable COLLATERAL_TOKEN;
    IERC20 public immutable BORROW_TOKEN;

    error UnexpectedBorrowCall();
    error UnexpectedRepayCall();
    error UnexpectedSupplyCall();

    constructor(IERC20 _collateralToken, IERC20 _borrowToken) {
        COLLATERAL_TOKEN = _collateralToken;
        BORROW_TOKEN = _borrowToken;
    }

    function getRealCollateralAssets(bool) external view returns (uint256) {
        return COLLATERAL_TOKEN.balanceOf(msg.sender);
    }

    function getRealBorrowAssets(bool) external view returns (uint256) {
        return BORROW_TOKEN.balanceOf(msg.sender);
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

    function initializeProtocol(bytes memory) external pure {}
}
