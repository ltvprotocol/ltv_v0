// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./MaxGrowthFeeStateReader.sol";
import "src/structs/state/low_level/MaxLowLevelRebalanceSharesState.sol";

contract MaxLowLevelRebalanceSharesStateReader is MaxGrowthFeeStateReader {
    function maxLowLevelRebalanceSharesState() internal view returns (MaxLowLevelRebalanceSharesState memory) {
        return MaxLowLevelRebalanceSharesState({
            maxGrowthFeeState: maxGrowthFeeState(),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
        });
    }
}
