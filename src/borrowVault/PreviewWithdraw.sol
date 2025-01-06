// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "./totalAssets.sol";
import "../ERC20.sol";
import "../Cases.sol";
import "../math/DepositWithdrawBorrow.sol";

abstract contract PreviewWithdraw is State, TotalAssets, ERC20, DepositWithdrawBorrow {

    using uMulDiv for uint256;

    function previewWithdraw(uint256 assets) external view returns (uint256 shares) {

        int256 signedShares = previewDepositWithdrawBorrow(int256(assets));
        
        if (signedShares < 0) {
            return 0;
        }

        uint256 supply = totalSupply;

        shares = supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());

        return shares;
    }

}
