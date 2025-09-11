// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ConvertCollateralData} from "src/structs/data/vault/convert/ConvertCollateralData.sol";
import {MaxGrowthFeeState} from "src/structs/state/common/MaxGrowthFeeState.sol";
import {MaxGrowthFeeData} from "src/structs/data/common/MaxGrowthFeeData.sol";
import {TotalAssetsState} from "src/structs/state/vault/total_assets/TotalAssetsState.sol";
import {TotalAssetsCollateralData} from "src/structs/data/vault/total_assets/TotalAssetsCollateralData.sol";
import {TotalAssetsCollateral} from "src/public/vault/read/collateral/TotalAssetsCollateral.sol";
import {MaxGrowthFee} from "src/math/abstracts/MaxGrowthFee.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title MaxGrowthFeeStateToConvertCollateralData
 * @notice Contract contains functionality to precalculate max growth fee state to
 * data needed for convert to assets/shares collateral calculations.
 */
abstract contract MaxGrowthFeeStateToConvertCollateralData is TotalAssetsCollateral, MaxGrowthFee {
    using UMulDiv for uint256;

    /**
     * @notice Precalculates max growth fee state to data needed for convert to assets/shares collateral calculations.
     */
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
