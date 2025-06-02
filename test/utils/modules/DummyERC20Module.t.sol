// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/elements/ERC20Module.sol";
import "./DummyTotalSupplyModule.t.sol";

contract DummyERC20Module is ERC20Module, DummyTotalSupplyModule {
    function totalSupply(uint256 supply) public pure override(TotalSupply, DummyTotalSupplyModule) returns (uint256) {
        return DummyTotalSupplyModule.totalSupply(supply);
    }
}
