// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

contract TotalSupply {
    function totalSupply(uint256 supply) public pure returns (uint256) {
        // add 100 to avoid vault inflation attack
        return supply + 100;
    }
}
