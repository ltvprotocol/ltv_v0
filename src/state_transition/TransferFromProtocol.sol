// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './Whitelist.sol';

contract TransferFromProtocol is Whitelist {
    function transferBorrowToken(address to, uint256 amount) internal isReceiverWhitelisted(to) {
        borrowToken.transfer(to, amount);
    }

    function transferCollateralToken(address to, uint256 amount) internal isReceiverWhitelisted(to) {
        collateralToken.transfer(to, amount);
    }
}
