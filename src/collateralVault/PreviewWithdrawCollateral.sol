// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import '../Constants.sol';
import '../borrowVault/TotalAssets.sol';
import '../math/DepositWithdraw.sol';

abstract contract PreviewWithdrawCollateral is TotalAssets {
    using uMulDiv for uint256;

    function previewWithdrawCollateral(uint256 assets) public view returns (uint256 shares) {
        Prices memory prices = getPrices();
        int256 sharesInUnderlying = DepositWithdraw.previewDepositWithdraw(-int256(assets), false, recoverConvertedAssets(), prices, targetLTV);

        if (sharesInUnderlying > 0) {
            return 0;
        } else {
            uint256 sharesInAssets = uint256(-sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, prices.borrow);
            shares = sharesInAssets.mulDivDown(totalSupply(), totalAssets());
        }

        return shares;
    }
}
