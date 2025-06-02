// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct MaxLowLevelRebalanceSharesData {
    uint256 realCollateral;
    uint256 realBorrow;
    uint256 maxTotalAssetsInUnderlying;
    uint256 supplyAfterFee;
    uint256 borrowPrice;
    uint256 depositTotalAssets;
}
