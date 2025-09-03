// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {MaxGrowthFeeState} from "src/structs/state/MaxGrowthFeeState.sol";
import {MaxGrowthFeeData} from "src/structs/data/MaxGrowthFeeData.sol";
import {TotalAssetsState} from "src/structs/state/vault/TotalAssetsState.sol";
import {TotalAssets} from "src/public/vault/borrow/TotalAssets.sol";
import {TotalSupply} from "src/public/erc20/TotalSupply.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract MaxGrowthFee is TotalAssets, TotalSupply {
    using uMulDiv for uint256;

    /**
     * @notice Calculates supply after applying max growth fee.
     *
     * @dev Calculations are derived from the ltv protocol paper.
     * Makes sure fee collector receives fee by minting tokens untill
     * the deviation of current token price from last seen token
     * price will be equal to (100 - maxGrowthFee)%
     *
     */
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

    /**
     * 
     * @notice Precalculates bare state needed to calculate max growth fee.
     */
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
