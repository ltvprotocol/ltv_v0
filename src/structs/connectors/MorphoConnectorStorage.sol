// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title MorphoConnectorStorage
 * @notice struct contains storage which is encoded in lending connector data
 * for morhpo connector
 */
struct MorphoConnectorStorage {
    address oracle;
    address irm;
    uint256 lltv;
    bytes32 marketId;
}
