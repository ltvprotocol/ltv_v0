// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "./TotalAssets.sol";
import "../ERC20.sol";
import "../Cases.sol";
import "../math/DepositWithdrawBorrow.sol";

abstract contract PreviewWithdraw is State, TotalAssets, ERC20, DepositWithdrawBorrow {

    using uMulDiv for uint256;

    function previewWithdraw(uint256 assets) external view returns (uint256 shares) {
        int256 sharesInUnderlying = previewDepositWithdrawBorrow(int256(assets));

        if (sharesInUnderlying > 0) {
            return 0;
        } else{
            uint256 sharesInAssets = uint256(-sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
            shares = sharesInAssets.mulDivDown(totalSupply(), totalAssets());
        }

        return shares;
    }

}
