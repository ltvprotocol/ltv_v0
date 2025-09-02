// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IWhitelistRegistry} from "src/interfaces/IWhitelistRegistry.sol";

/**
 * @title WhitelistRegistry
 * @notice This contract is used to manage the whitelist of addresses. LTV protocol uses
 * this contract to allow only whitelisted addresses to receive any assets from the protocol.
 * Contract has owner, which can add and remove addresses from the whitelist. Also user
 * can add to whitelist himself by submitting signature of the signer. User can acquire whitelist
 * by signature only once.
 */
contract WhitelistRegistry is IWhitelistRegistry, Ownable {
    mapping(address => bool) public isAddressWhitelisted;

    event AddressWhitelisted(address indexed account, bool isWhitelisted);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function addAddressToWhitelist(address account) external onlyOwner {
        isAddressWhitelisted[account] = true;
        emit AddressWhitelisted(account, true);
    }

    function removeAddressFromWhitelist(address account) external onlyOwner {
        isAddressWhitelisted[account] = false;
        emit AddressWhitelisted(account, false);
    }
}
