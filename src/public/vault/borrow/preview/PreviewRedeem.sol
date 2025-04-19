// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../Vault.sol';
import '../../../../math2/MintRedeem.sol';

abstract contract PreviewRedeem is Vault {
    using uMulDiv for uint256;

    function previewRedeem(uint256 shares, VaultState memory state) public pure returns (uint256 assets) {
        return _previewRedeem(shares, vaultStateToData(state));
    }

    function _previewRedeem(uint256 shares, VaultData memory data) internal pure returns (uint256 assets) {
        // HODLer <=> withdrawer conflict, round in favor of HODLer, round down to give less assets for provided shares
        uint256 sharesInUnderlying = shares.mulDivDown(data.totalAssets, data.supplyAfterFee).mulDivDown(data.borrowPrice, Constants.ORACLE_DIVIDER);
        
        int256 assetsInUnderlying = MintRedeem.previewMintRedeem(
            MintRedeemData({
                collateral: data.collateral,
                borrow: data.borrow,
                futureBorrow: data.futureBorrow,
                futureCollateral: data.futureCollateral,
                userFutureRewardBorrow: data.userFutureRewardBorrow,
                userFutureRewardCollateral: data.userFutureRewardCollateral,
                protocolFutureRewardBorrow: data.protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: data.protocolFutureRewardCollateral,
                collateralSlippage: data.collateralSlippage,
                borrowSlippage: data.borrowSlippage,
                targetLTV: data.targetLTV,
                deltaShares: -1 * int256(sharesInUnderlying),
                isBorrow: true
            })
        );

        if (assetsInUnderlying < 0) {
            return 0;
        }

        // HODLer <=> withdrawer conflict, round in favor of HODLer, give less assets
        return uint256(assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, data.borrowPrice);
    }
} 