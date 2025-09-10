// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "src/structs/state/common/MaxGrowthFeeState.sol";
import {TotalAssetsState} from "src/structs/state/vault/total_assets/TotalAssetsState.sol";
import {TotalAssetsStateReader} from "src/state_reader/vault/TotalAssetsStateReader.sol";

contract MaxGrowthFeeStateReader is TotalAssetsStateReader {
    function maxGrowthFeeState() internal view returns (MaxGrowthFeeState memory) {
        TotalAssetsState memory withdrawTotalAssetsState = totalAssetsState(false);
        return MaxGrowthFeeState({
            commonTotalAssetsState: withdrawTotalAssetsState.commonTotalAssetsState,
            withdrawRealCollateralAssets: withdrawTotalAssetsState.realCollateralAssets,
            withdrawRealBorrowAssets: withdrawTotalAssetsState.realBorrowAssets,
            maxGrowthFeeDividend: maxGrowthFeeDividend,
            maxGrowthFeeDivider: maxGrowthFeeDivider,
            supply: baseTotalSupply,
            lastSeenTokenPrice: lastSeenTokenPrice
        });
    }
}
