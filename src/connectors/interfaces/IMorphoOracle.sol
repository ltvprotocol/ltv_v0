// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IMorphoOracle {
    function price() external view returns (uint256);
}
