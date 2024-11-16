// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./borrowVault/PreviewDeposit.sol";
import "./borrowVault/PreviewWithdraw.sol";

contract LTV is PreviewWithdraw, PreviewDeposit {

    constructor(string memory _name, uint _value) ERC20("LTV", "LTV", 18) {
        //
    }

}
