// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './TotalAssets.sol';

abstract contract MaxGrowthFee is TotalAssets {
    using uMulDiv for uint256;

    function previewSupplyAfterFee(MaxGrowthFeeState memory state) internal pure returns (uint256) {
        return _previewSupplyAfterFee(maxGrowthFeeStateToData(state));
    }

    function _previewSupplyAfterFee(MaxGrowthFeeData memory data) internal pure returns (uint256) {

        // underestimate current price
        if (data.totalAssets.mulDivDown(Constants.LAST_SEEN_PRICE_PRECISION, data.supply) <= data.lastSeenTokenPrice) {
            return data.supply;
        }

        // divident: asset * supply
        // divisor: supply * maxGrowthFee * lastSeenTokenPrice + assets * (1 - maxGrowthFee)

        // underestimate new supply to mint less tokens
        return
            data.totalAssets.mulDivDown(
                data.supply,
                data.supply.mulDivUp(
                    data.maxGrowthFee * data.lastSeenTokenPrice,
                    Constants.LAST_SEEN_PRICE_PRECISION * Constants.MAX_GROWTH_FEE_DIVIDER
                ) + data.totalAssets.mulDivUp(Constants.MAX_GROWTH_FEE_DIVIDER - data.maxGrowthFee, Constants.MAX_GROWTH_FEE_DIVIDER)
            );
    }

    function maxGrowthFeeStateToData(MaxGrowthFeeState memory state) internal pure returns (MaxGrowthFeeData memory) {
        return MaxGrowthFeeData({
        // fee collector has the lowest priority, so need to underestimate reward
            totalAssets: totalAssets(false, state.totalAssetsState),
            maxGrowthFee: state.maxGrowthFee,
            supply: state.supply,
            lastSeenTokenPrice: state.lastSeenTokenPrice
        });
    }
}
