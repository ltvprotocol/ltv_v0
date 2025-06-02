// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../public/vault/borrow/convert/ConvertToAssets.sol";
import "../public/vault/borrow/convert/ConvertToShares.sol";
import "../public/vault/borrow/execute/Deposit.sol";
import "../public/vault/borrow/execute/Mint.sol";
import "../public/vault/borrow/execute/Redeem.sol";
import "../public/vault/borrow/execute/Withdraw.sol";

contract BorrowVaultModule is Redeem, Withdraw, Deposit, Mint, ConvertToShares, ConvertToAssets {}
