// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../Constants.sol";
import "../borrowVault/TotalAssets.sol";
import "../math/DepositWithdraw.sol";
import "../math/MintRedeem.sol";
import '../MaxGrowthFee.sol';

abstract contract PreviewWithdrawCollateral is MaxGrowthFee, DepositWithdraw, MintRedeem {
    using uMulDiv for uint256;

    function previewWithdrawCollateral(uint256 assets) public view returns (uint256 shares) {
        int256 sharesInUnderlying = previewDepositWithdraw(-int256(assets), false);

        if (sharesInUnderlying > 0) {
            return 0;
        } else{
            uint256 sharesInAssets = uint256(-sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle());
            shares = sharesInAssets.mulDivDown(previewSupplyAfterFee(), totalAssets());
        }

        return shares;
    }

}
