// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../MaxGrowthFee.sol";
import "src/structs/data/vault/ConvertCollateralData.sol";
import "src/public/vault/collateral/TotalAssetsCollateral.sol";

abstract contract MaxGrowthFeeStateToConvertCollateralData is TotalAssetsCollateral, MaxGrowthFee {
    using uMulDiv for uint256;

    function maxGrowthFeeStateToConvertCollateralData(MaxGrowthFeeState memory state)
        internal
        pure
        returns (ConvertCollateralData memory)
    {
        ConvertCollateralData memory data;
        uint256 withdrawTotalAssets = totalAssets(
            false,
            TotalAssetsState({
                realBorrowAssets: state.withdrawRealBorrowAssets,
                realCollateralAssets: state.withdrawRealCollateralAssets,
                commonTotalAssetsState: state.commonTotalAssetsState
            })
        );

        data.totalAssetsCollateral = _totalAssetsCollateral(
            false,
            TotalAssetsCollateralData({
                totalAssets: withdrawTotalAssets,
                collateralPrice: state.commonTotalAssetsState.collateralPrice,
                borrowPrice: state.commonTotalAssetsState.borrowPrice
            })
        );

        data.supplyAfterFee = _previewSupplyAfterFee(
            MaxGrowthFeeData({
                withdrawTotalAssets: withdrawTotalAssets,
                maxGrowthFeeDividend: state.maxGrowthFeeDividend,
                maxGrowthFeeDivider: state.maxGrowthFeeDivider,
                supply: totalSupply(state.supply),
                lastSeenTokenPrice: state.lastSeenTokenPrice
            })
        );

        return data;
    }
}
