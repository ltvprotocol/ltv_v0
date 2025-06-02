// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../Constants.sol";

abstract contract TotalSupply {
    function totalSupply(uint256 supply) public pure virtual returns (uint256) {
        // add 100 to avoid vault inflation attack
        return supply + Constants.VIRTUAL_ASSETS_AMOUNT;
    }
}
