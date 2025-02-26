// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import './borrowVault/TotalAssets.sol';
import './ERC20.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

abstract contract MaxGrowthFee is TotalAssets, ERC20, OwnableUpgradeable {
    using uMulDiv for uint256;

    function setMaxGrowthFee(uint256 _maxGrowthFee) external onlyOwner {
        maxGrowthFee = _maxGrowthFee;
    }

    function previewSupplyAfterFee() internal view returns (uint256) {
        uint256 assets = totalAssets();
        uint256 supply = totalSupply();

        if (assets.mulDivDown(Constants.LAST_SEEN_PRICE_PRECISION, supply) < lastSeenTokenPrice) {
            return supply;
        }

        return (assets * supply) / (maxGrowthFee * lastSeenTokenPrice * supply / Constants.LAST_SEEN_PRICE_PRECISION / Constants.MAX_GROWTH_FEE_DIVIDER 
            + (Constants.MAX_GROWTH_FEE_DIVIDER - maxGrowthFee) * assets / Constants.MAX_GROWTH_FEE_DIVIDER)
            - supply;
    }

    function applyMaxGrowthFee(uint256 supplyAfterFee) internal {
        uint256 supply = totalSupply();
        if (supplyAfterFee > supply) {
            _mint(FEE_COLLECTOR, supplyAfterFee - supply);
            lastSeenTokenPrice = totalAssets().mulDivDown(Constants.LAST_SEEN_PRICE_PRECISION, supplyAfterFee);
        }
    }
}
