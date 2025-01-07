// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./borrowVault/PreviewDeposit.sol";
import "./borrowVault/PreviewWithdraw.sol";
import "./borrowVault/PreviewMint.sol";
import "./borrowVault/PreviewRedeem.sol";
import "./borrowVault/Deposit.sol";
import "./borrowVault/Withdraw.sol";

contract LTV is PreviewWithdraw, PreviewDeposit, PreviewMint, PreviewRedeem, Deposit, Withdraw {

    constructor(string memory _name, uint _value) ERC20("LTV", "LTV", 18) {
        //
    }

}
