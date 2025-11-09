// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Deposit} from "../../public/vault/write/borrow/execute/Deposit.sol";
import {Mint} from "../../public/vault/write/borrow/execute/Mint.sol";
import {Redeem} from "../../public/vault/write/borrow/execute/Redeem.sol";
import {Withdraw} from "../../public/vault/write/borrow/execute/Withdraw.sol";
import {ConvertToAssets} from "../../public/vault/read/borrow/convert/ConvertToAssets.sol";
import {ConvertToShares} from "../../public/vault/read/borrow/convert/ConvertToShares.sol";

/**
 * @title BorrowVaultModule
 * @notice Borrow vault module for LTV protocol
 */
contract BorrowVaultModule is Redeem, Withdraw, Deposit, Mint, ConvertToShares, ConvertToAssets {
    constructor() {
        _disableInitializers();
    }
}
