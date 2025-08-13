// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

library Constants {
    uint256 public constant ORACLE_DIVIDER = 10 ** 18;
    int256 public constant SLIPPAGE_PRECISION = 10 ** 18;
    uint256 public constant LAST_SEEN_PRICE_PRECISION = 10 ** 18;
    uint256 public constant VIRTUAL_ASSETS_AMOUNT = 10 ** 4;

    uint8 public constant IS_DEPOSIT_DISABLED_BIT = 0;
    uint8 public constant IS_WITHDRAW_DISABLED_BIT = 1;
    uint8 public constant IS_WHITELIST_ACTIVATED_BIT = 2;
    uint8 public constant IS_VAULT_DELEVERAGED_BIT = 3;
}
