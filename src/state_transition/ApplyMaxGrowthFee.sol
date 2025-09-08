// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {ERC20} from "src/state_transition/ERC20.sol";
import {TotalSupply} from "src/public/erc20/read/TotalSupply.sol";
import {TotalAssets} from "src/public/vault/read/borrow/TotalAssets.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract ApplyMaxGrowthFee is TotalAssets, TotalSupply, ERC20 {
    using uMulDiv for uint256;

    function applyMaxGrowthFee(uint256 supplyAfterFee, uint256 withdrawTotalAssets) internal {
        uint256 supply = totalSupply(baseTotalSupply);
        if (supplyAfterFee > supply) {
            _mint(feeCollector, supplyAfterFee - supply);
            // round new token price to the top to underestimate next fee
            lastSeenTokenPrice = withdrawTotalAssets.mulDivUp(Constants.LAST_SEEN_PRICE_PRECISION, supplyAfterFee);
        }
    }
}
