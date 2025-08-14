// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/public/vault/borrow/TotalAssets.sol";
import "src/public/erc20/TotalSupply.sol";
import "src/structs/state/MaxGrowthFeeState.sol";
import "src/structs/data/MaxGrowthFeeData.sol";

abstract contract MaxGrowthFee is TotalAssets, TotalSupply {
    using uMulDiv for uint256;

    function _previewSupplyAfterFee(MaxGrowthFeeData memory data) internal pure returns (uint256) {
        // underestimate current price
        if (
            data.withdrawTotalAssets.mulDivDown(Constants.LAST_SEEN_PRICE_PRECISION, data.supply)
                <= data.lastSeenTokenPrice
        ) {
            return data.supply;
        }

        // divident: asset * supply
        // divisor: supply * maxGrowthFee * lastSeenTokenPrice + assets * (1 - maxGrowthFee)

        // underestimate new supply to mint less tokens
        return data.withdrawTotalAssets.mulDivDown(
            data.supply,
            data.supply.mulDivUp(
                data.maxGrowthFeeDividend * data.lastSeenTokenPrice,
                Constants.LAST_SEEN_PRICE_PRECISION * data.maxGrowthFeeDivider
            )
                + data.withdrawTotalAssets.mulDivUp(
                    data.maxGrowthFeeDivider - data.maxGrowthFeeDividend, data.maxGrowthFeeDivider
                )
        );
    }

    function maxGrowthFeeStateToData(MaxGrowthFeeState memory state) internal pure returns (MaxGrowthFeeData memory) {
        return MaxGrowthFeeData({
            withdrawTotalAssets: totalAssets(
                false,
                TotalAssetsState({
                    realCollateralAssets: state.withdrawRealCollateralAssets,
                    realBorrowAssets: state.withdrawRealBorrowAssets,
                    commonTotalAssetsState: state.commonTotalAssetsState
                })
            ),
            maxGrowthFeeDividend: state.maxGrowthFeeDividend,
            maxGrowthFeeDivider: state.maxGrowthFeeDivider,
            supply: totalSupply(state.supply),
            lastSeenTokenPrice: state.lastSeenTokenPrice
        });
    }
}
