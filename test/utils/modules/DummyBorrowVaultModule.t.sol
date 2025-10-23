// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {TotalAssetsData} from "src/structs/data/vault/total_assets/TotalAssetsData.sol";
import {TotalAssets} from "src/public/vault/read/borrow/TotalAssets.sol";
import {TotalSupply} from "src/public/erc20/read/TotalSupply.sol";
import {BorrowVaultModule} from "src/elements/modules/BorrowVaultModule.sol";
import {DummyTotalAssetsModule} from "test/utils/modules/DummyTotalAssetsModule.t.sol";
import {DummyTotalSupplyModule} from "test/utils/modules/DummyTotalSupplyModule.t.sol";

contract DummyBorrowVaultModule is BorrowVaultModule, DummyTotalAssetsModule, DummyTotalSupplyModule {
    function _totalAssets(bool isDeposit, TotalAssetsData memory data)
        internal
        pure
        override(TotalAssets, DummyTotalAssetsModule)
        returns (uint256)
    {
        return DummyTotalAssetsModule._totalAssets(isDeposit, data);
    }

    function _totalSupply(uint256 supply)
        internal
        pure
        override(TotalSupply, DummyTotalSupplyModule)
        returns (uint256)
    {
        return DummyTotalSupplyModule._totalSupply(supply);
    }
}
