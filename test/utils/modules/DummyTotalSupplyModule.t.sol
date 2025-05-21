// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/public/erc20/TotalSupply.sol';

contract DummyTotalSupplyModule is TotalSupply {
    function totalSupply(uint256 supply) public virtual override pure returns (uint256) {
        return super.totalSupply(supply) - Constants.VIRTUAL_ASSETS_AMOUNT;
    }
}
