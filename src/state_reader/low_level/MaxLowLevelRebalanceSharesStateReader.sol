// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxLowLevelRebalanceSharesState} from "src/structs/state/low_level/MaxLowLevelRebalanceSharesState.sol";
import {MaxGrowthFeeStateReader} from "src/state_reader/MaxGrowthFeeStateReader.sol";

contract MaxLowLevelRebalanceSharesStateReader is MaxGrowthFeeStateReader {
    function maxLowLevelRebalanceSharesState() internal view returns (MaxLowLevelRebalanceSharesState memory) {
        (uint256 depositRealCollateralAssets, uint256 depositRealBorrowAssets) = getRealCollateralAndRealBorrowAssets(true);
        return MaxLowLevelRebalanceSharesState({
            // overestimate assets for smaller border
            maxGrowthFeeState: maxGrowthFeeState(),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying,
            depositRealBorrowAssets: depositRealBorrowAssets,
            depositRealCollateralAssets: depositRealCollateralAssets
        });
    }
}
