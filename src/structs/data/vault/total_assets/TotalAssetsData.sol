// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title TotalAssetsData
 * @notice This struct needed for total assets calculations
 */
struct TotalAssetsData {
    int256 collateral;
    int256 borrow;
    uint256 borrowPrice;
    uint8 borrowTokenDecimals;
}
