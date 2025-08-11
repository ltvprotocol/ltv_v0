// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../../Constants.sol";
import "../../../../utils/MulDiv.sol";
import "../preview/PreviewMintCollateral.sol";
import "../preview/PreviewDepositCollateral.sol";

abstract contract MaxDepositCollateral is PreviewMintCollateral, PreviewDepositCollateral {
    using uMulDiv for uint256;

    function maxDepositCollateral(MaxDepositMintCollateralVaultState memory state) public pure returns (uint256) {
        return _maxDepositCollateral(maxDepositMintCollateralVaultStateToMaxDepositMintCollateralVaultData(state));
    }

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
        uint256 minProfitRealCollateral = data.minProfitLTVDividend == 0
            ? type(uint128).max
            : uint256(data.realBorrow).mulDivDown(data.minProfitLTVDivider, data.minProfitLTVDividend);

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
