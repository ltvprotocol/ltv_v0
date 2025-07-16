// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../preview/PreviewRedeemCollateral.sol";
import "../preview/PreviewWithdrawCollateral.sol";

abstract contract MaxRedeemCollateral is PreviewWithdrawCollateral, PreviewRedeemCollateral {
    using uMulDiv for uint256;

    function maxRedeemCollateral(MaxWithdrawRedeemCollateralVaultState memory state) public pure returns (uint256) {
        return _maxRedeemCollateral(maxWithdrawRedeemCollateralVaultStateToMaxWithdrawRedeemCollateralVaultData(state));
    }

    function _maxRedeemCollateral(MaxWithdrawRedeemCollateralVaultData memory data) internal pure returns (uint256) {
        // round up to assume smaller border
        uint256 maxSafeRealCollateral = uint256(data.realBorrow).mulDivUp(Constants.LTV_DIVIDER, data.maxSafeLTV);

        if (maxSafeRealCollateral >= uint256(data.realCollateral)) {
            return 0;
        }

        // round down to assume smaller border
        uint256 maxWithdrawInAssets = (uint256(data.realCollateral) - maxSafeRealCollateral).mulDivDown(
            Constants.ORACLE_DIVIDER, data.previewCollateralVaultData.collateralPrice
        );

        (uint256 maxWithdrawInShares,) =
            _previewWithdrawCollateral(maxWithdrawInAssets, data.previewCollateralVaultData);

        return maxWithdrawInShares < data.ownerBalance ? maxWithdrawInShares : data.ownerBalance;
    }
}
