// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/elements/CollateralVaultModule.sol";
import "./DummyTotalAssetsModule.t.sol";
import "./DummyTotalSupplyModule.t.sol";

contract DummyCollateralVaultModule is CollateralVaultModule, DummyTotalAssetsModule, DummyTotalSupplyModule {
    function _totalAssets(bool isDeposit, TotalAssetsData memory data)
        public
        pure
        override(TotalAssets, DummyTotalAssetsModule)
        returns (uint256)
    {
        return DummyTotalAssetsModule._totalAssets(isDeposit, data);
    }

    function totalSupply(uint256 supply) public pure override(TotalSupply, DummyTotalSupplyModule) returns (uint256) {
        return DummyTotalSupplyModule.totalSupply(supply);
    }
}
