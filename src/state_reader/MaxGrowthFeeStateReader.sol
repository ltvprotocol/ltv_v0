// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./vault/TotalAssetsStateReader.sol";
import "src/structs/state/MaxGrowthFeeState.sol";

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
