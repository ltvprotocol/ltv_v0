// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface ILendingErrors {
    error InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error InsufficientBalance(address account, uint256 balance, uint256 needed);
    error TransferFailed(address from, address to, uint256 amount);
    error InvalidAmount(uint256 amount);
    error BorrowFailed(address from, address to, uint256 amount);
    error RepayFailed(address from, address to, uint256 amount);
    error SupplyFailed(address from, address to, uint256 amount);
    error WithdrawFailed(address from, address to, uint256 amount);
}
