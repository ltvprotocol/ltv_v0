// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxLowLevelRebalanceSharesState} from "src/structs/state/low_level/max/MaxLowLevelRebalanceSharesState.sol";
import {MaxGrowthFeeStateReader} from "src/state_reader/common/MaxGrowthFeeStateReader.sol";

/**
 * @title MaxLowLevelRebalanceSharesStateReader
 * @notice contract contains functionality to retrieve pure state needed for
 * max low level rebalance shares calculations
 */
contract MaxLowLevelRebalanceSharesStateReader is MaxGrowthFeeStateReader {
    /**
     * @dev function to retrieve pure state needed for max low level rebalance shares
     */
    function maxLowLevelRebalanceSharesState() internal view returns (MaxLowLevelRebalanceSharesState memory) {
        (uint256 depositRealCollateralAssets, uint256 depositRealBorrowAssets) =
            getRealCollateralAndRealBorrowAssets(true);
        return MaxLowLevelRebalanceSharesState({
            // overestimate assets for smaller border
            maxGrowthFeeState: maxGrowthFeeState(),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying,
            depositRealBorrowAssets: depositRealBorrowAssets,
            depositRealCollateralAssets: depositRealCollateralAssets
        });
    }
}
