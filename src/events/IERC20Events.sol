// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IERC20Events {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
