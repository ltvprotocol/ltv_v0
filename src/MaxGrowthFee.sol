// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import './collateralVault/TotalAssetsCollateral.sol';
import './ERC20.sol';

abstract contract MaxGrowthFee is TotalAssetsCollateral, ERC20 {
    using uMulDiv for uint256;

    function setMaxGrowthFee(uint256 _maxGrowthFee) external onlyOwner {
        maxGrowthFee = _maxGrowthFee;
    }

    function previewSupplyAfterFee() internal view returns (uint256) {
        // fee collector has the lowest priority, so need to underestimate reward
        uint256 assets = _totalAssets(false);
        uint256 supply = totalSupply();

        // underestimate current price
        if (assets.mulDivDown(Constants.LAST_SEEN_PRICE_PRECISION, supply) <= lastSeenTokenPrice) {
            return supply;
        }

        // divident: asset * supply
        // divisor: supply * maxGrowthFee * lastSeenTokenPrice + assets * (1 - maxGrowthFee)
        
        // underestimate new supply to mint less tokens
        return assets.mulDivDown(
              supply,
              supply.mulDivUp(
                    maxGrowthFee * lastSeenTokenPrice,
                    Constants.LAST_SEEN_PRICE_PRECISION * Constants.MAX_GROWTH_FEE_DIVIDER
              ) 
              + assets.mulDivUp(
                    Constants.MAX_GROWTH_FEE_DIVIDER - maxGrowthFee,
                    Constants.MAX_GROWTH_FEE_DIVIDER
              )
        );
    }

    function applyMaxGrowthFee(uint256 supplyAfterFee) internal {
        uint256 supply = totalSupply();
        if (supplyAfterFee > supply) {
            _mint(feeCollector, supplyAfterFee - supply);
            // round new token price to the top to underestimate next fee
            lastSeenTokenPrice = _totalAssets(true).mulDivUp(Constants.LAST_SEEN_PRICE_PRECISION, supplyAfterFee);
        }
    }
}
