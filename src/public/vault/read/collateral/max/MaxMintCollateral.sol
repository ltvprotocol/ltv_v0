// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintCollateralVaultState} from "src/structs/state/vault/max/MaxDepositMintCollateralVaultState.sol";
import {MaxDepositMintCollateralVaultData} from "src/structs/data/vault/max/MaxDepositMintCollateralVaultData.sol";
import {PreviewMintCollateral} from "src/public/vault/read/collateral/preview/PreviewMintCollateral.sol";
import {PreviewDepositCollateral} from "src/public/vault/read/collateral/preview/PreviewDepositCollateral.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title MaxMintCollateral
 * @notice This contract contains max mint collateral function implementation.
 */
abstract contract MaxMintCollateral is PreviewMintCollateral, PreviewDepositCollateral {
    using UMulDiv for uint256;

    /**
     * @dev see ICollateralVaultModule.maxMintCollateral
     */
    function maxMintCollateral(MaxDepositMintCollateralVaultState memory state) external view nonReentrantRead returns (uint256) {
        return _maxMintCollateral(maxDepositMintCollateralVaultStateToMaxDepositMintCollateralVaultData(state));
    }

    /**
     * @dev base function to calculate max mint collateral
     */
    function _maxMintCollateral(MaxDepositMintCollateralVaultData memory data) internal pure returns (uint256) {
        uint256 availableSpaceInShares = getAvailableSpaceInShares(
            data.previewCollateralVaultData.collateral,
            data.previewCollateralVaultData.borrow,
            data.maxTotalAssetsInUnderlying,
            data.previewCollateralVaultData.supplyAfterFee,
            data.previewCollateralVaultData.totalAssetsCollateral,
            data.previewCollateralVaultData.collateralPrice,
            data.previewCollateralVaultData.collateralTokenDecimals
        );

        // round down to assume smaller border
        uint256 minProfitRealCollateral = data.minProfitLtvDividend == 0
            ? type(uint128).max
            : uint256(data.realBorrow).mulDivDown(data.minProfitLtvDivider, data.minProfitLtvDividend);

        if (uint256(data.realCollateral) >= minProfitRealCollateral) {
            return 0;
        }

        uint256 maxDepositInUnderlying = minProfitRealCollateral - uint256(data.realCollateral);
        // round down to assume smaller border
        uint256 maxDepositInCollateral = maxDepositInUnderlying.mulDivDown(
            10 ** data.previewCollateralVaultData.collateralTokenDecimals,
            data.previewCollateralVaultData.collateralPrice
        );
        (uint256 maxMintShares,) = _previewDepositCollateral(maxDepositInCollateral, data.previewCollateralVaultData);

        return maxMintShares > availableSpaceInShares ? availableSpaceInShares : maxMintShares;
    }
}
