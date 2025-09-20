// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxGrowthFeeState} from "src/structs/state/common/MaxGrowthFeeState.sol";
import {ConvertCollateralData} from "src/structs/data/vault/convert/ConvertCollateralData.sol";
import {VaultCollateral} from "src/math/abstracts/VaultCollateral.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title ConvertToAssetsCollateral
 * @notice This contract contains convert to assets collateral function implementation.
 */
abstract contract ConvertToAssetsCollateral is VaultCollateral {
    using UMulDiv for uint256;

    /**
     * @dev see ICollateralVaultModule.convertToAssetsCollateral
     */
    function convertToAssetsCollateral(uint256 shares, MaxGrowthFeeState memory state)
        external
        pure
        returns (uint256)
    {
        return _convertToAssetsCollateral(shares, maxGrowthFeeStateToConvertCollateralData(state));
    }

    /**
     * @dev base function to calculate convert to assets collateral
     */
    function _convertToAssetsCollateral(uint256 shares, ConvertCollateralData memory data)
        internal
        pure
        returns (uint256)
    {
        return shares.mulDivDown(data.totalAssetsCollateral, data.supplyAfterFee);
    }
}
