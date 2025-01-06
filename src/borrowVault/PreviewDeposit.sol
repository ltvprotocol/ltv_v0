// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "./totalAssets.sol";
import "../ERC20.sol";
import "../Cases.sol";
import "../math/DepositWithdrawallBorrow.sol";

abstract contract PreviewDeposit is State, TotalAssets, ERC20, DepositWithdrawallBorrow {

    using uMulDiv for uint256;

    function previewDeposit(uint256 assets) external view returns (uint256 shares) {

        int256 signedShares = previewDepositWithdrawallBorrow(-1*int256(assets));
        
        if (signedShares > 0) {
            return 0;
        }

        uint256 supply = totalSupply;

        uint256 shares = supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());

        return shares;
    }

}
