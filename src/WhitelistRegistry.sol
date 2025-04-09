// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import '@openzeppelin/contracts/access/Ownable.sol';

contract WhitelistRegistry is Ownable {
    mapping(address => bool) public isAddressWhitelisted;

    event AddressWhitelisted(address indexed account, bool isWhitelisted);

    constructor (address initialOwner) Ownable(initialOwner) {}

    function addAddressToWhitelist(address account) external onlyOwner {
        isAddressWhitelisted[account] = true;
        emit AddressWhitelisted(account, true);
    }

    function removeAddressFromWhitelist(address account) external onlyOwner {
        isAddressWhitelisted[account] = false;
        emit AddressWhitelisted(account, false);
    }
}