// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './ERC20.sol';
import '../public/erc20/TotalSupply.sol';
import '../public/vault/borrow/TotalAssets.sol';

contract ApplyMaxGrowthFee is TotalAssets, TotalSupply, ERC20 {
    using uMulDiv for uint256;

    function applyMaxGrowthFee(uint256 supplyAfterFee, uint256 depositTotalAssets) internal {
        uint256 supply = totalSupply(baseTotalSupply);
        if (supplyAfterFee > supply) {
            _mint(feeCollector, supplyAfterFee - supply);
            // round new token price to the top to underestimate next fee
            lastSeenTokenPrice = depositTotalAssets.mulDivUp(Constants.LAST_SEEN_PRICE_PRECISION, supplyAfterFee);
        }
    }
}