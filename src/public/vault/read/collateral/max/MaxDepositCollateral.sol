// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/constants/Constants.sol";
import {MaxDepositMintCollateralVaultState} from "src/structs/state/vault/max/MaxDepositMintCollateralVaultState.sol";
import {MaxDepositMintCollateralVaultData} from "src/structs/data/vault/max/MaxDepositMintCollateralVaultData.sol";
import {PreviewMintCollateral} from "src/public/vault/read/collateral/preview/PreviewMintCollateral.sol";
import {PreviewDepositCollateral} from "src/public/vault/read/collateral/preview/PreviewDepositCollateral.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title MaxDepositCollateral
 * @notice This contract contains max deposit collateral function implementation.
 */
abstract contract MaxDepositCollateral is PreviewMintCollateral, PreviewDepositCollateral {
    using UMulDiv for uint256;

    /**
     * @dev see ICollateralVaultModule.maxDepositCollateral
     */
    function maxDepositCollateral(MaxDepositMintCollateralVaultState memory state) public pure returns (uint256) {
        return _maxDepositCollateral(maxDepositMintCollateralVaultStateToMaxDepositMintCollateralVaultData(state));
    }

    /**
     * @dev base function to calculate max deposit collateral
     */
    function _maxDepositCollateral(MaxDepositMintCollateralVaultData memory data) internal pure returns (uint256) {
        uint256 availableSpaceInShares = getAvailableSpaceInShares(
            data.previewCollateralVaultData.collateral,
            data.previewCollateralVaultData.borrow,
            data.maxTotalAssetsInUnderlying,
            data.previewCollateralVaultData.supplyAfterFee,
            data.previewCollateralVaultData.totalAssetsCollateral,
            data.previewCollateralVaultData.collateralPrice
        );
        (uint256 availableSpaceInCollateral,) =
            _previewMintCollateral(availableSpaceInShares, data.previewCollateralVaultData);

        // round down to assume smaller border
        uint256 minProfitRealCollateral = data.minProfitLtvDividend == 0
            ? type(uint128).max
            : uint256(data.realBorrow).mulDivDown(data.minProfitLtvDivider, data.minProfitLtvDividend);

        if (uint256(data.realCollateral) >= minProfitRealCollateral) {
            return 0;
        }

        uint256 maxDepositInUnderlying = minProfitRealCollateral - uint256(data.realCollateral);
        // round down to assume smaller border
        uint256 maxDepositInCollateral =
            maxDepositInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, data.previewCollateralVaultData.collateralPrice);

        return maxDepositInCollateral > availableSpaceInCollateral ? availableSpaceInCollateral : maxDepositInCollateral;
    }
}
