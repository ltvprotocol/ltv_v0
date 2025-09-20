// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Deposit} from "src/public/vault/write/borrow/execute/Deposit.sol";
import {Mint} from "src/public/vault/write/borrow/execute/Mint.sol";
import {Redeem} from "src/public/vault/write/borrow/execute/Redeem.sol";
import {Withdraw} from "src/public/vault/write/borrow/execute/Withdraw.sol";
import {ConvertToAssets} from "src/public/vault/read/borrow/convert/ConvertToAssets.sol";
import {ConvertToShares} from "src/public/vault/read/borrow/convert/ConvertToShares.sol";
import {Asset} from "src/public/vault/read/borrow/Asset.sol";

/**
 * @title BorrowVaultModule
 * @notice Borrow vault module for LTV protocol
 */
contract BorrowVaultModule is Redeem, Withdraw, Deposit, Mint, ConvertToShares, ConvertToAssets, Asset {
    constructor() {
        _disableInitializers();
    }
}
