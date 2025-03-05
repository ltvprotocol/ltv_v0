// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./TotalAssets.sol";
import "../ERC20.sol";
import "../utils/MulDiv.sol";

abstract contract ConvertToShares is TotalAssets, ERC20 {

    using uMulDiv for uint256;

    function convertToShares(uint256 assets) external view virtual returns (uint256) {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }
}