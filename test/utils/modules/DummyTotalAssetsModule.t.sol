// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/constants/Constants.sol";
import {TotalAssetsData} from "src/structs/data/vault/total_assets/TotalAssetsData.sol";
import {TotalAssets} from "src/public/vault/read/borrow/TotalAssets.sol";


contract DummyTotalAssetsModule is TotalAssets {
    function _totalAssets(bool isDeposit, TotalAssetsData memory data)
        internal
        pure
        virtual
        override
        returns (uint256)
    {
        return super._totalAssets(isDeposit, data) - Constants.VIRTUAL_ASSETS_AMOUNT;
    }
}
