// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "./totalAssets.sol";
import "../ERC20.sol";
import "../Cases.sol";
import "../math/MintRedeamBorrow.sol";

abstract contract PreviewRedeem is State, MintRedeamBorrow {

    using uMulDiv for uint256;

    function previewRedeem(uint256 shares) external view returns (uint256 assets) {

        int256 signedAssets = previewMintRedeamBorrow(-1*int256(assets));

        if (signedAssets < 0) {
            return 0;
        }

        return uint256(signedAssets);
    }

}
