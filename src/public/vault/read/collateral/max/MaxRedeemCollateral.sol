// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/constants/Constants.sol";
import {MaxWithdrawRedeemCollateralVaultState} from
    "src/structs/state/vault/max/MaxWithdrawRedeemCollateralVaultState.sol";
import {MaxWithdrawRedeemCollateralVaultData} from "src/structs/data/vault/max/MaxWithdrawRedeemCollateralVaultData.sol";
import {PreviewRedeemCollateral} from "src/public/vault/read/collateral/preview/PreviewRedeemCollateral.sol";
import {PreviewWithdrawCollateral} from "src/public/vault/read/collateral/preview/PreviewWithdrawCollateral.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

abstract contract MaxRedeemCollateral is PreviewWithdrawCollateral, PreviewRedeemCollateral {
    using UMulDiv for uint256;

    function maxRedeemCollateral(MaxWithdrawRedeemCollateralVaultState memory state) public pure returns (uint256) {
        return _maxRedeemCollateral(maxWithdrawRedeemCollateralVaultStateToMaxWithdrawRedeemCollateralVaultData(state));
    }

    function _maxRedeemCollateral(MaxWithdrawRedeemCollateralVaultData memory data) internal pure returns (uint256) {
        // round up to assume smaller border
        uint256 maxSafeRealCollateral =
            uint256(data.realBorrow).mulDivUp(data.maxSafeLtvDivider, data.maxSafeLtvDividend);

        if (maxSafeRealCollateral >= uint256(data.realCollateral)) {
            return 0;
        }

        // round down to assume smaller border
        uint256 maxWithdrawInAssets = (uint256(data.realCollateral) - maxSafeRealCollateral).mulDivDown(
            Constants.ORACLE_DIVIDER, data.previewCollateralVaultData.collateralPrice
        );

        if (maxWithdrawInAssets <= 3) {
            return 0;
        }

        (uint256 maxWithdrawInShares,) =
            _previewWithdrawCollateral(maxWithdrawInAssets - 3, data.previewCollateralVaultData);

        (uint256 maxWithdrawInAssetsWithDelta,) =
            _previewRedeemCollateral(maxWithdrawInShares, data.previewCollateralVaultData);

        if (maxWithdrawInAssetsWithDelta > maxWithdrawInAssets) {
            uint256 delta = maxWithdrawInAssetsWithDelta + 3 - maxWithdrawInAssets;
            if (maxWithdrawInShares < 2 * delta) {
                return 0;
            }
            maxWithdrawInShares = maxWithdrawInShares - 2 * delta;
        }

        return maxWithdrawInShares < data.ownerBalance ? maxWithdrawInShares : data.ownerBalance;
    }
}
