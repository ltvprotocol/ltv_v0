// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../MaxGrowthFeeState.sol";

struct PreviewVaultState {
    MaxGrowthFeeState maxGrowthFeeState;
    uint16 targetLTVDividend;
    uint16 targetLTVDivider;
    uint256 startAuction;
    uint256 blockNumber;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
}
