// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxWithdrawRedeemCollateralVaultState} from
    "src/structs/state/vault/max/MaxWithdrawRedeemCollateralVaultState.sol";
import {MaxWithdrawRedeemCollateralVaultData} from "src/structs/data/vault/max/MaxWithdrawRedeemCollateralVaultData.sol";
import {PreviewRedeemCollateral} from "src/public/vault/read/collateral/preview/PreviewRedeemCollateral.sol";
import {PreviewWithdrawCollateral} from "src/public/vault/read/collateral/preview/PreviewWithdrawCollateral.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title MaxRedeemCollateral
 * @notice This contract contains max redeem collateral function implementation.
 */
abstract contract MaxRedeemCollateral is PreviewWithdrawCollateral, PreviewRedeemCollateral {
    using UMulDiv for uint256;

    /**
     * @dev see ICollateralVaultModule.maxRedeemCollateral
     */
    function maxRedeemCollateral(MaxWithdrawRedeemCollateralVaultState memory state) public pure returns (uint256) {
        return _maxRedeemCollateral(maxWithdrawRedeemCollateralVaultStateToMaxWithdrawRedeemCollateralVaultData(state));
    }

    /**
     * @dev base function to calculate max redeem collateral
     */
    function _maxRedeemCollateral(MaxWithdrawRedeemCollateralVaultData memory data) internal pure returns (uint256) {
        // round up to assume smaller border
        uint256 maxSafeRealCollateral =
            uint256(data.realBorrow).mulDivUp(data.maxSafeLtvDivider, data.maxSafeLtvDividend);

        if (maxSafeRealCollateral >= uint256(data.realCollateral)) {
            return 0;
        }

        // round down to assume smaller border
        uint256 maxWithdrawInUnderlying = uint256(data.realCollateral) - maxSafeRealCollateral;

        if (maxWithdrawInUnderlying <= 3) {
            return 0;
        }

        (uint256 maxWithdrawSharesInUnderlying,) =
            _previewWithdrawCollateralInUnderlying(maxWithdrawInUnderlying - 3, data.previewCollateralVaultData);

        (uint256 maxWithdrawInAssetsWithDelta,) =
            _previewRedeemCollateralInUnderlying(maxWithdrawSharesInUnderlying, data.previewCollateralVaultData);

        if (maxWithdrawInAssetsWithDelta > maxWithdrawInUnderlying) {
            uint256 delta = maxWithdrawInAssetsWithDelta + 3 - maxWithdrawInUnderlying;
            if (maxWithdrawSharesInUnderlying < 2 * delta) {
                return 0;
            }
            maxWithdrawSharesInUnderlying = maxWithdrawSharesInUnderlying - 2 * delta;
        }

        uint256 maxWithdrawShares = maxWithdrawSharesInUnderlying.mulDivDown(
            10 ** data.previewCollateralVaultData.collateralTokenDecimals,
            data.previewCollateralVaultData.collateralPrice
        ).mulDivDown(
            data.previewCollateralVaultData.supplyAfterFee, data.previewCollateralVaultData.totalAssetsCollateral
        );

        return maxWithdrawShares < data.ownerBalance ? maxWithdrawShares : data.ownerBalance;
    }
}
