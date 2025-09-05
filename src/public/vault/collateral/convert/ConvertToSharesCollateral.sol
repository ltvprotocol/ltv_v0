// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "src/structs/state/MaxGrowthFeeState.sol";
import {ConvertCollateralData} from "src/structs/data/vault/ConvertCollateralData.sol";
import {VaultCollateral} from "src/math/VaultCollateral.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

/**
 * @title ConvertToSharesCollateral
 * @notice This contract contains convert to shares collateral function implementation.
 */
abstract contract ConvertToSharesCollateral is VaultCollateral {
    using uMulDiv for uint256;

    /**
     * @dev see ICollateralVaultModule.convertToSharesCollateral
     */
    function convertToSharesCollateral(uint256 assets, MaxGrowthFeeState memory state)
        external
        pure
        returns (uint256)
    {
        return _convertToSharesCollateral(assets, maxGrowthFeeStateToConvertCollateralData(state));
    }

    /**
     * @dev base function to calculate convert to shares collateral
     */
    function _convertToSharesCollateral(uint256 assets, ConvertCollateralData memory data)
        internal
        pure
        returns (uint256)
    {
        if (data.totalAssetsCollateral == 0) {
            return 0;
        }
        return assets.mulDivDown(data.supplyAfterFee, data.totalAssetsCollateral);
    }
}
