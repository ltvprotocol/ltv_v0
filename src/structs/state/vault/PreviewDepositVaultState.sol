// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../MaxGrowthFeeState.sol";

struct PreviewDepositVaultState {
    MaxGrowthFeeState maxGrowthFeeState;
    uint256 depositRealBorrowAssets;
    uint256 depositRealCollateralAssets;
    uint16 targetLTVDividend;
    uint16 targetLTVDivider;
    uint56 startAuction;
    uint24 auctionDuration;
    uint56 blockNumber;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
}
