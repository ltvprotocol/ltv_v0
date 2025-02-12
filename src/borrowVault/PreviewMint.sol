// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../Constants.sol";
import "./TotalAssets.sol";
import "../math/MintRedeem.sol";
import '../math/DepositWithdraw.sol';

abstract contract PreviewMint is TotalAssets, DepositWithdraw, MintRedeem {

    using uMulDiv for uint256;

    function previewMint(uint256 shares) external view returns (uint256 assets) {

        uint256 sharesInAssets = shares.mulDivUp(totalAssets(), totalSupply());
        uint256 sharesInUnderlying = sharesInAssets.mulDivUp(getPrices().borrow, Constants.ORACLE_DIVIDER);

        int256 assetsInUnderlying = previewMintRedeem(int256(sharesInUnderlying));
        // int256 signedShares = previewMintRedeem(-1*int256(assets));

        if (assetsInUnderlying > 0) {
            return 0;
        }

        return uint256(-assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
    }

}
