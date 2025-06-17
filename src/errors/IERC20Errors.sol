// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IERC20Errors {
    error TransferToZeroAddress();
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
}
