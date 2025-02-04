// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./borrowVault/PreviewDeposit.sol";
import "./borrowVault/PreviewWithdraw.sol";
import "./borrowVault/PreviewMint.sol";
import "./borrowVault/PreviewRedeem.sol";
import "./borrowVault/Deposit.sol";
import "./borrowVault/Withdraw.sol";
import './borrowVault/Redeem.sol';
import './borrowVault/Mint.sol';
import './utils/Ownable.sol';
import './borrowVault/ConvertToAssets.sol';
import './borrowVault/ConvertToShares.sol';

abstract contract LTV is PreviewWithdraw, PreviewDeposit, PreviewMint, PreviewRedeem, Mint, Deposit, Withdraw, Redeem, ConvertToAssets, ConvertToShares, Ownable {

    constructor(address initialOwner) ERC20("LTV", "LTV", 18) Ownable(initialOwner) {
        //
    }

}
