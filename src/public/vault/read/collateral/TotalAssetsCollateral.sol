// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {TotalAssetsState} from "../../../../structs/state/vault/total_assets/TotalAssetsState.sol";
import {TotalAssetsCollateralData} from "../../../../structs/data/vault/total_assets/TotalAssetsCollateralData.sol";
import {TotalAssetsCollateralStateToData} from "../../../../math/abstracts/state_to_data/TotalAssetsCollateralStateToData.sol";
import {UMulDiv} from "../../../../math/libraries/MulDiv.sol";

/**
 * @title TotalAssetsCollateral
 * @notice This contract contains total assets collateral function implementation.
 */
abstract contract TotalAssetsCollateral is TotalAssetsCollateralStateToData {
    using UMulDiv for uint256;

    /**
     * @dev see ICollateralVaultModule.totalAssetsCollateral
     */
    function totalAssetsCollateral(TotalAssetsState memory state) external view nonReentrantRead returns (uint256) {
        // default behavior - don't overestimate our assets
        return _totalAssetsCollateral(false, state);
    }

    /**
     * @dev see ICollateralVaultModule.totalAssetsCollateral
     */
    function totalAssetsCollateral(bool isDeposit, TotalAssetsState memory state)
        external
        view
        virtual
        nonReentrantRead
        returns (uint256)
    {
        return _totalAssetsCollateral(isDeposit, state);
    }

    function _totalAssetsCollateral(bool isDeposit, TotalAssetsState memory state) internal pure returns (uint256) {
        return _totalAssetsCollateral(isDeposit, totalAssetsStateToTotalAssetsCollateralData(state, isDeposit));
    }

    /**
     * @dev base function to calculate total assets collateral
     */
    function _totalAssetsCollateral(bool isDeposit, TotalAssetsCollateralData memory data)
        internal
        pure
        returns (uint256)
    {
        return data.totalAssets.mulDiv(data.borrowPrice, data.collateralPrice, isDeposit).mulDiv(
            10 ** data.collateralTokenDecimals, 10 ** data.borrowTokenDecimals, isDeposit
        );
    }
}
