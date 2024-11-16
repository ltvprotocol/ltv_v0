// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "./totalAssets.sol";
import "../ERC20.sol";
import "../utils/MulDiv.sol";

abstract contract ConvertToShares is State, TotalAssets, ERC20 {

    using MulDiv for uint256;

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }
}