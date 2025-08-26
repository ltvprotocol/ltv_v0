// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {TotalAssetsData} from "src/structs/data/vault/TotalAssetsData.sol";
import {CollateralVaultModule} from "src/elements/CollateralVaultModule.sol";
import {TotalAssets} from "src/public/vault/borrow/TotalAssets.sol";
import {TotalSupply} from "src/public/erc20/TotalSupply.sol";
import {DummyTotalAssetsModule} from "test/utils/modules/DummyTotalAssetsModule.t.sol";
import {DummyTotalSupplyModule} from "test/utils/modules/DummyTotalSupplyModule.t.sol";

contract DummyCollateralVaultModule is CollateralVaultModule, DummyTotalAssetsModule, DummyTotalSupplyModule {
    function _totalAssets(bool isDeposit, TotalAssetsData memory data)
        internal
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
