// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../Constants.sol";
import "./TotalAssets.sol";
import "../math/DepositWithdraw.sol";
import '../math/MintRedeem.sol';

abstract contract PreviewWithdraw is TotalAssets, DepositWithdraw, MintRedeem {

    using uMulDiv for uint256;

    function previewWithdraw(uint256 assets) public view returns (uint256 shares) {
        int256 sharesInUnderlying = previewDepositWithdraw(int256(assets), true);

        if (sharesInUnderlying > 0) {
            return 0;
        } else{
            uint256 sharesInAssets = uint256(-sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
            shares = sharesInAssets.mulDivDown(totalSupply(), totalAssets());
        }

        return shares;
    }

}
