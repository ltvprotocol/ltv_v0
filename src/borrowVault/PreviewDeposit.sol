// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../Constants.sol";
import "../math/DepositWithdraw.sol";
import "../math/MintRedeem.sol";
import '../MaxGrowthFee.sol';

abstract contract PreviewDeposit is MaxGrowthFee, DepositWithdraw, MintRedeem {

    using uMulDiv for uint256;

    function previewDeposit(uint256 assets) public view returns (uint256 shares) {

        int256 sharesInUnderlying = previewDepositWithdraw(-1*int256(assets), true);

        uint256 sharesInAssets;
        if (sharesInUnderlying < 0) {
            return 0;
        } else {
            sharesInAssets = uint256(sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
        }

        return sharesInAssets.mulDivDown(previewSupplyAfterFee(), totalAssets());
    }

}
