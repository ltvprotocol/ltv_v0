// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/public/vault/borrow/TotalAssets.sol';

contract DummyTotalAssetsModule is TotalAssets {
    function _totalAssets(bool isDeposit, TotalAssetsData memory data) public virtual override pure returns (uint256) {
        return super._totalAssets(isDeposit, data) - Constants.VIRTUAL_ASSETS_AMOUNT;
    }
}