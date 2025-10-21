// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/constants/Constants.sol";
import {TotalSupply} from "src/public/erc20/read/TotalSupply.sol";

contract DummyTotalSupplyModule is TotalSupply {
    function _totalSupply(uint256 supply) internal pure virtual override returns (uint256) {
        return supply;
    }
}
