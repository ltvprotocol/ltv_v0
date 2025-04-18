// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './TotalAssets.sol';

struct MaxGrowthFeeState {
    TotalAssetsState totalAssetsState;
    uint256 maxGrowthFee;
    uint256 supply;
    uint256 lastSeenTokenPrice;
}

abstract contract MaxGrowthFee is TotalAssets {
    using uMulDiv for uint256;

    function previewSupplyAfterFee(MaxGrowthFeeState memory state) internal pure returns (uint256) {
        // fee collector has the lowest priority, so need to underestimate reward
        uint256 assets = totalAssets(false, state.totalAssetsState);
        uint256 supply = state.supply;

        // underestimate current price
        if (assets.mulDivDown(Constants.LAST_SEEN_PRICE_PRECISION, supply) <= state.lastSeenTokenPrice) {
            return supply;
        }

        // divident: asset * supply
        // divisor: supply * maxGrowthFee * lastSeenTokenPrice + assets * (1 - maxGrowthFee)

        // underestimate new supply to mint less tokens
        return
            assets.mulDivDown(
                supply,
                supply.mulDivUp(
                    state.maxGrowthFee * state.lastSeenTokenPrice,
                    Constants.LAST_SEEN_PRICE_PRECISION * Constants.MAX_GROWTH_FEE_DIVIDER
                ) + assets.mulDivUp(Constants.MAX_GROWTH_FEE_DIVIDER - state.maxGrowthFee, Constants.MAX_GROWTH_FEE_DIVIDER)
            );
    }
}
