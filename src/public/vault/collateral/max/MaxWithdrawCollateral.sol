// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../preview/PreviewWithdrawCollateral.sol';
import '../preview/PreviewRedeemCollateral.sol';

abstract contract MaxWithdrawCollateral is PreviewWithdrawCollateral, PreviewRedeemCollateral {
    using uMulDiv for uint256;

    function maxWithdrawCollateral(MaxWithdrawRedeemCollateralVaultState memory state) public pure returns (uint256) {
        return _maxWithdrawCollateral(maxWithdrawRedeemCollateralVaultStateToMaxWithdrawRedeemCollateralVaultData(state));
    }

    function _maxWithdrawCollateral(MaxWithdrawRedeemCollateralVaultData memory data) internal pure returns (uint256) {
        // round down to assume smaller border
        uint256 maxSafeRealCollateral = uint256(data.realBorrow).mulDivDown(Constants.LTV_DIVIDER, data.maxSafeLTV);

        if (maxSafeRealCollateral >= uint256(data.realCollateral)) {
            return 0;
        }

        // round down to assume smaller border
        uint256 vaultWithdrawInAssets = uint256(data.realCollateral) -
            maxSafeRealCollateral.mulDivDown(Constants.ORACLE_DIVIDER, data.previewCollateralVaultData.collateralPrice);

        (uint256 ownerBalanceAssets, ) = _previewRedeemCollateral(data.ownerBalance, data.previewCollateralVaultData);

        return ownerBalanceAssets < vaultWithdrawInAssets ? ownerBalanceAssets : vaultWithdrawInAssets;
    }
}
