// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "src/structs/state/common/MaxGrowthFeeState.sol";

/**
 * @title MaxLowLevelRebalanceSharesState
 * @notice This struct needed for max low level rebalance shares calculations
 */
struct MaxLowLevelRebalanceSharesState {
    MaxGrowthFeeState maxGrowthFeeState;
    uint256 depositRealBorrowAssets;
    uint256 depositRealCollateralAssets;
    uint256 maxTotalAssetsInUnderlying;
    uint8 borrowTokenDecimals;
}
