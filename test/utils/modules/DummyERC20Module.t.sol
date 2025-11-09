// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ERC20Module} from "../../../src/elements/modules/ERC20Module.sol";
import {TotalSupply} from "../../../src/public/erc20/read/TotalSupply.sol";
import {DummyTotalSupplyModule} from "./DummyTotalSupplyModule.t.sol";

contract DummyERC20Module is ERC20Module, DummyTotalSupplyModule {
    function _totalSupply(uint256 supply)
        internal
        pure
        override(TotalSupply, DummyTotalSupplyModule)
        returns (uint256)
    {
        return DummyTotalSupplyModule._totalSupply(supply);
    }
}
