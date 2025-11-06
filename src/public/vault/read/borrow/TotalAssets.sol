// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "../../../../constants/Constants.sol";
import {TotalAssetsData} from "../../../../structs/data/vault/total_assets/TotalAssetsData.sol";
import {TotalAssetsState} from "../../../../structs/state/vault/total_assets/TotalAssetsState.sol";
import {TotalAssetsStateToData} from "../../../../math/abstracts/state_to_data/TotalAssetsStateToData.sol";
import {UMulDiv} from "../../../../math/libraries/MulDiv.sol";
import {NonReentrantRead} from "../../../../modifiers/NonReentrantRead.sol";

/**
 * @title TotalAssets
 * @notice This contract contains total assets function implementation.
 */
abstract contract TotalAssets is TotalAssetsStateToData, NonReentrantRead {
    using UMulDiv for uint256;

    /**
     * @dev see IBorrowVaultModule.totalAssets
     */
    function totalAssets(TotalAssetsState memory state) external view nonReentrantRead returns (uint256) {
        // default behavior - don't overestimate our assets
        return _totalAssets(false, state);
    }

    /**
     * @dev see IBorrowVaultModule.totalAssets
     */
    function totalAssets(bool isDeposit, TotalAssetsState memory state)
        external
        view
        nonReentrantRead
        returns (uint256)
    {
        return _totalAssets(isDeposit, state);
    }

    function _totalAssets(bool isDeposit, TotalAssetsState memory state) internal pure virtual returns (uint256) {
        return _totalAssets(isDeposit, totalAssetsStateToData(state, isDeposit));
    }

    /**
     * @dev base function to calculate total assets
     */
    function _totalAssets(bool isDeposit, TotalAssetsData memory data) internal pure virtual returns (uint256) {
        // Add virtual assets to avoid vault attack
        // in case of deposit need to overestimate our assets
        return uint256(data.collateral - data.borrow).mulDiv(
            10 ** data.borrowTokenDecimals, data.borrowPrice, isDeposit
        ) + Constants.VIRTUAL_ASSETS_AMOUNT;
    }
}
