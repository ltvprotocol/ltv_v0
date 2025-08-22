// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct MorphoConnectorStorage {
    address oracle;
    address irm;
    uint256 lltv;
    bytes32 marketId;
}
