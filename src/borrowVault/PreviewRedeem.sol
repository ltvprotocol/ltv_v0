// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../Constants.sol";
import '../MaxGrowthFee.sol';
import "../math/MintRedeem.sol";
import "../math/DepositWithdraw.sol";

abstract contract PreviewRedeem is MaxGrowthFee, DepositWithdraw, MintRedeem {

    using uMulDiv for uint256;

    function previewRedeem(uint256 shares) external view returns (uint256 assets) {
        uint256 sharesInAssets = shares.mulDivUp(totalAssets(), previewSupplyAfterFee());
        uint256 sharesInUnderlying = sharesInAssets.mulDivUp(getPrices().borrow, Constants.ORACLE_DIVIDER);
        int256 assetsInUnderlying = previewMintRedeem(-1*int256(sharesInUnderlying), true);

        if (assetsInUnderlying < 0) {
            return 0;
        }

        return uint256(assetsInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
    }

}
