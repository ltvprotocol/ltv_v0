// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

interface IWhitelistRegistry {
    function isAddressWhitelisted(address account) external view returns (bool);
}