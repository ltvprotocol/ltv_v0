// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../Constants.sol";
import "./TotalAssets.sol";
import "../math/DepositWithdraw.sol";
import "../math/MintRedeem.sol";

abstract contract PreviewDeposit is TotalAssets, DepositWithdraw, MintRedeem {

    using uMulDiv for uint256;

    function previewDeposit(uint256 assets) public view returns (uint256 shares) {

        int256 sharesInUnderlying = previewDepositWithdraw(-1*int256(assets), true);

        uint256 sharesInAssets;
        if (sharesInUnderlying < 0) {
            return 0;
        } else {
            sharesInAssets = uint256(sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
        }

        return sharesInAssets.mulDivDown(totalSupply(), totalAssets());
    }

}
