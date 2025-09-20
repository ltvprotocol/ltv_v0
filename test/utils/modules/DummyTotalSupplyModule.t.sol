// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/constants/Constants.sol";
import {TotalSupply} from "src/public/erc20/read/TotalSupply.sol";

contract DummyTotalSupplyModule is TotalSupply {
    function totalSupply(uint256 supply) public pure virtual override returns (uint256) {
        return super.totalSupply(supply) - Constants.VIRTUAL_ASSETS_AMOUNT;
    }
}
