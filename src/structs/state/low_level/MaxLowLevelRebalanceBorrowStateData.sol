// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

struct MaxLowLevelRebalanceBorrowStateData {
    uint256 realBorrowAssets;
    uint256 maxTotalAssetsInUnderlying;
    uint16 targetLTVDividend;
    uint16 targetLTVDivider;
    uint256 borrowPrice;
}
