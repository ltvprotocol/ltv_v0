// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/constants/Constants.sol";
import {ERC20} from "src/state_transition/ERC20.sol";
import {TotalSupply} from "src/public/erc20/read/TotalSupply.sol";
import {TotalAssets} from "src/public/vault/read/borrow/TotalAssets.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title ApplyMaxGrowthFee
 * @notice contract contains functionality to apply max growth fee
 */
abstract contract ApplyMaxGrowthFee is TotalAssets, TotalSupply, ERC20 {
    using UMulDiv for uint256;

    /**
     * @dev sends provided max growth fee to the fee collector and updates last seen token price
     */
    function applyMaxGrowthFee(uint256 supplyAfterFee, uint256 withdrawTotalAssets) internal {
        uint256 supply = totalSupply(baseTotalSupply);
        if (supplyAfterFee > supply) {
            _mintToFeeCollector(supplyAfterFee - supply);
            // round new token price to the top to underestimate next fee
            lastSeenTokenPrice = withdrawTotalAssets.mulDivUp(Constants.LAST_SEEN_PRICE_PRECISION, supplyAfterFee);
        }
    }
}
