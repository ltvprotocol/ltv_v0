// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "src/structs/state/common/MaxGrowthFeeState.sol";
import {TotalAssetsState} from "src/structs/state/vault/total_assets/TotalAssetsState.sol";
import {TotalAssetsStateReader} from "src/state_reader/vault/TotalAssetsStateReader.sol";

/**
 * @title MaxGrowthFeeStateReader
 * @notice contract contains functionality to retrieve pure state needed for
 * max growth fee calculations
 */
contract MaxGrowthFeeStateReader is TotalAssetsStateReader {
    /**
     * @dev function to retrieve pure state needed for max growth fee calculations
     */
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
