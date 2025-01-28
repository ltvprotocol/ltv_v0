// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "./TotalAssets.sol";
import "../ERC20.sol";
import "../Cases.sol";
import "../math/MintRedeamBorrow.sol";

abstract contract PreviewRedeem is State, TotalAssets, MintRedeamBorrow {

    using uMulDiv for uint256;

    function previewRedeem(uint256 shares) external view returns (uint256 assets) {
        uint256 sharesInAssets = shares.mulDivUp(totalAssets(), totalSupply());
        uint256 sharesInUnderlying = sharesInAssets.mulDivUp(getPrices().borrow, Constants.ORACLE_DIVIDER);
        int256 assetsInUnderlying = previewMintRedeamBorrow(-1*int256(sharesInUnderlying));

        if (assetsInUnderlying < 0) {
            return 0;
        }

        return uint256(sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
    }

}
