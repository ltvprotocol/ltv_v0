// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IAaveV3Oracle {
    function getAssetPrice(address asset) external view returns (uint256);
}
