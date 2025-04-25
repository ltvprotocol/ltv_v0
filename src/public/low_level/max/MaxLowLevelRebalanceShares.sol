// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import 'src/Structs2.sol';
import 'src/Constants.sol';
import 'src/utils/MulDiv.sol';
import 'src/math2/CommonMath.sol';
import 'src/math2/MaxGrowthFee.sol';

contract MaxLowLevelRebalanceShares is MaxGrowthFee {
    using sMulDiv for int256;

    function maxLowLevelRebalanceShares(MaxLowLevelRebalanceSharesState memory state) public pure returns (int256) {
        return _maxLowLevelRebalanceShares(maxLowLevelRebalanceSharesStateToData(state));
    }

    function _maxLowLevelRebalanceShares(MaxLowLevelRebalanceSharesData memory data) public pure returns (int256) {
        int256 maxDeltaSharesInUnderlying = int256(data.maxTotalAssetsInUnderlying + data.realBorrow) - int256(data.realCollateral);

        // rounding down assuming smaller border
        return
            maxDeltaSharesInUnderlying.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice)).mulDivDown(
                int256(data.supplyAfterFee),
                int256(data.depositTotalAssets)
            );
    }

    function maxLowLevelRebalanceSharesStateToData(
        MaxLowLevelRebalanceSharesState memory state
    ) public pure returns (MaxLowLevelRebalanceSharesData memory data) {
        // true since we calculate top border
        data.realCollateral = CommonMath.convertRealCollateral(
            state.maxGrowthFeeState.totalAssetsState.realCollateralAssets,
            state.maxGrowthFeeState.totalAssetsState.collateralPrice,
            true
        );
        data.realBorrow = CommonMath.convertRealBorrow(
            state.maxGrowthFeeState.totalAssetsState.realBorrowAssets,
            state.maxGrowthFeeState.totalAssetsState.borrowPrice,
            true
        );

        data.depositTotalAssets = totalAssets(true, state.maxGrowthFeeState.totalAssetsState);

        uint256 withdrawTotalAssets = totalAssets(false, state.maxGrowthFeeState.totalAssetsState);

        data.supplyAfterFee = _previewSupplyAfterFee(
            MaxGrowthFeeData({
                withdrawTotalAssets: withdrawTotalAssets,
                maxGrowthFee: state.maxGrowthFeeState.maxGrowthFee,
                supply: totalSupply(state.maxGrowthFeeState.supply),
                lastSeenTokenPrice: state.maxGrowthFeeState.lastSeenTokenPrice
            })
        );

        data.maxTotalAssetsInUnderlying = state.maxTotalAssetsInUnderlying;
        data.borrowPrice = state.maxGrowthFeeState.totalAssetsState.borrowPrice;
    }
}
