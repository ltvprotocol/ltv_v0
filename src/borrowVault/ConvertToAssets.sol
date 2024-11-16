// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import "./totalAssets.sol";
import "../ERC20.sol";
import "../utils/MulDiv.sol";

abstract contract ConvertToAssets is State, TotalAssets, ERC20 {

    using MulDiv for uint256;

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }
}