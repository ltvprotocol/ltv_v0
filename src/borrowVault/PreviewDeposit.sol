// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../Constants.sol';
import '../math/DepositWithdraw.sol';
import '../MaxGrowthFee.sol';

abstract contract PreviewDeposit is MaxGrowthFee {
    using uMulDiv for uint256;

    function previewDeposit(uint256 assets) public view returns (uint256) {
        Prices memory prices = getPrices();
        int256 sharesInUnderlying = DepositWithdraw.previewDepositWithdraw(-1 * int256(assets), true, recoverConvertedAssets(true), prices, targetLTV);

        if (sharesInUnderlying < 0) {
            return 0;
        }

        // round down to mint less shares
        return uint256(sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, prices.borrow).mulDivDown(previewSupplyAfterFee(), totalAssets());
    }
}
