// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

library Constants {
    uint256 public constant AMOUNT_OF_STEPS = 1000;
    uint256 public constant ORACLE_DIVIDER = 10**18;
    int256 public constant SLIPPAGE_PRECISION = 10**18;
    uint256 public constant LTV_DIVIDER = 10**18;
}