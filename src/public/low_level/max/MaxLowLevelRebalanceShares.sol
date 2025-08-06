// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import "src/Constants.sol";
import "src/utils/MulDiv.sol";
import "src/math/CommonMath.sol";
import "src/math/MaxGrowthFee.sol";
import "src/structs/state/low_level/MaxLowLevelRebalanceSharesState.sol";
import "src/structs/data/low_level/MaxLowLevelRebalanceSharesData.sol";

abstract contract MaxLowLevelRebalanceShares is MaxGrowthFee {
    using sMulDiv for int256;

    function maxLowLevelRebalanceShares(MaxLowLevelRebalanceSharesState memory state) public pure returns (int256) {
        return _maxLowLevelRebalanceShares(maxLowLevelRebalanceSharesStateToData(state));
    }

    function _maxLowLevelRebalanceShares(MaxLowLevelRebalanceSharesData memory data) public pure returns (int256) {
        int256 maxDeltaSharesInUnderlying =
            int256(data.maxTotalAssetsInUnderlying + data.depositRealBorrow) - int256(data.depositRealCollateral);

        // rounding down assuming smaller border
        return maxDeltaSharesInUnderlying.mulDivDown(int256(Constants.ORACLE_DIVIDER), int256(data.borrowPrice))
            .mulDivDown(int256(data.supplyAfterFee), int256(data.depositTotalAssets));
    }

    function maxLowLevelRebalanceSharesStateToData(MaxLowLevelRebalanceSharesState memory state)
        public
        pure
        returns (MaxLowLevelRebalanceSharesData memory data)
    {
        // true since we calculate top border
        data.depositRealCollateral = CommonMath.convertRealCollateral(
            state.depositRealCollateralAssets, state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice, true
        );
        data.depositRealBorrow = CommonMath.convertRealBorrow(
            state.depositRealBorrowAssets, state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice, true
        );

        int256 futureCollateral = CommonMath.convertFutureCollateral(
            state.maxGrowthFeeState.commonTotalAssetsState.futureCollateralAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
            true
        );
        int256 futureBorrow = CommonMath.convertFutureBorrow(
            state.maxGrowthFeeState.commonTotalAssetsState.futureBorrowAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            true
        );
        int256 futureRewardCollateral = CommonMath.convertFutureRewardCollateral(
            state.maxGrowthFeeState.commonTotalAssetsState.futureRewardCollateralAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
            true
        );
        int256 futureRewardBorrow = CommonMath.convertFutureRewardBorrow(
            state.maxGrowthFeeState.commonTotalAssetsState.futureRewardBorrowAssets,
            state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
            true
        );

        {
            int256 depositCollateral = int256(data.depositRealCollateral) + futureCollateral + futureRewardCollateral;
            int256 depositBorrow = int256(data.depositRealBorrow) + futureBorrow + futureRewardBorrow;

            data.depositTotalAssets = _totalAssets(
                true,
                TotalAssetsData({
                    collateral: depositCollateral,
                    borrow: depositBorrow,
                    borrowPrice: state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice
                })
            );
        }
        {
            uint256 withdrawTotalAssets = totalAssets(
                false,
                TotalAssetsState({
                    commonTotalAssetsState: state.maxGrowthFeeState.commonTotalAssetsState,
                    realCollateralAssets: state.maxGrowthFeeState.withdrawRealCollateralAssets,
                    realBorrowAssets: state.maxGrowthFeeState.withdrawRealBorrowAssets
                })
            );
            data.supplyAfterFee = _previewSupplyAfterFee(
                MaxGrowthFeeData({
                    withdrawTotalAssets: withdrawTotalAssets,
                    maxGrowthFeeDividend: state.maxGrowthFeeState.maxGrowthFeeDividend,
                    maxGrowthFeeDivider: state.maxGrowthFeeState.maxGrowthFeeDivider,
                    supply: totalSupply(state.maxGrowthFeeState.supply),
                    lastSeenTokenPrice: state.maxGrowthFeeState.lastSeenTokenPrice
                })
            );
        }

        data.maxTotalAssetsInUnderlying = state.maxTotalAssetsInUnderlying;
        data.borrowPrice = state.maxGrowthFeeState.commonTotalAssetsState.borrowPrice;
    }
}
