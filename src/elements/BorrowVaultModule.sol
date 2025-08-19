// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Deposit} from "src/public/vault/borrow/execute/Deposit.sol";
import {Mint} from "src/public/vault/borrow/execute/Mint.sol";
import {Redeem} from "src/public/vault/borrow/execute/Redeem.sol";
import {Withdraw} from "src/public/vault/borrow/execute/Withdraw.sol";
import {ConvertToAssets} from "src/public/vault/borrow/convert/ConvertToAssets.sol";
import {ConvertToShares} from "src/public/vault/borrow/convert/ConvertToShares.sol";

contract BorrowVaultModule is Redeem, Withdraw, Deposit, Mint, ConvertToShares, ConvertToAssets {}
