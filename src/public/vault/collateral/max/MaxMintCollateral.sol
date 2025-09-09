// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {MaxDepositMintCollateralVaultState} from "src/structs/state/vault/MaxDepositMintCollateralVaultState.sol";
import {MaxDepositMintCollateralVaultData} from "src/structs/data/vault/MaxDepositMintCollateralVaultData.sol";
import {PreviewMintCollateral} from "src/public/vault/collateral/preview/PreviewMintCollateral.sol";
import {PreviewDepositCollateral} from "src/public/vault/collateral/preview/PreviewDepositCollateral.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

/**
 * @title MaxMintCollateral
 * @notice This contract contains max mint collateral function implementation.
 */
abstract contract MaxMintCollateral is PreviewMintCollateral, PreviewDepositCollateral {
    using uMulDiv for uint256;

    /**
     * @dev see ICollateralVaultModule.maxMintCollateral
     */
    function maxMintCollateral(MaxDepositMintCollateralVaultState memory state) public pure returns (uint256) {
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
            data.previewCollateralVaultData.collateralPrice
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
        uint256 maxDepositInCollateral =
            maxDepositInUnderlying.mulDivDown(Constants.ORACLE_DIVIDER, data.previewCollateralVaultData.collateralPrice);
        (uint256 maxMintShares,) = _previewDepositCollateral(maxDepositInCollateral, data.previewCollateralVaultData);

        return maxMintShares > availableSpaceInShares ? availableSpaceInShares : maxMintShares;
    }
}
