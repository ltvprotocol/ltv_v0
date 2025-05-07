// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

abstract contract AdministrationEvents {
    event MaxSafeLTVChanged(uint128 oldValue, uint128 newValue);
    event MinProfitLTVChanged(uint128 oldValue, uint128 newValue);
    event TargetLTVChanged(uint128 oldValue, uint128 newValue);
    event WhitelistRegistryUpdated(address oldValue, address newValue);
}