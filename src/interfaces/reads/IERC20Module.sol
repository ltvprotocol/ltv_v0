// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IERC20Module {
    function totalSupply(uint256 baseTotalSupply) external view returns (uint256);
}
