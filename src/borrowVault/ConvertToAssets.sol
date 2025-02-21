// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./TotalAssets.sol";
import "../ERC20.sol";
import "../utils/MulDiv.sol";

abstract contract ConvertToAssets is TotalAssets, ERC20 {

    using uMulDiv for uint256;

    function convertToAssets(uint256 shares) external view virtual returns (uint256) {
        return shares.mulDivDown(totalAssets(), totalSupply());
    }
}