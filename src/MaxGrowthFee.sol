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
        uint256 assets = totalAssets();
        uint256 supply = totalSupply();

        // round token price to the bottom
        if (assets.mulDivDown(Constants.LAST_SEEN_PRICE_PRECISION, supply) <= lastSeenTokenPrice) {
            return supply;
        }

        // divident: asset * supply
        // divisor: supply * maxGrowthFee * lastSeenTokenPrice + assets * (1 - maxGrowthFee)
        
        // round new supply to the bottom to avoid minting more tokens than needed
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
            // round token price to the bottom
            lastSeenTokenPrice = totalAssets().mulDivDown(Constants.LAST_SEEN_PRICE_PRECISION, supplyAfterFee);
        }
    }
}
