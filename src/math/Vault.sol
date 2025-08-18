// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "src/Constants.sol";
import {MaxDepositMintStateToData} from "src/math/state_to_data/max/MaxDepositMintStateToData.sol";
import {MaxWithdrawRedeemStateToData} from "src/math/state_to_data/max/MaxWithdrawRedeemStateToData.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract Vault is MaxDepositMintStateToData, MaxWithdrawRedeemStateToData {
    using uMulDiv for uint256;

    function getAvailableSpaceInShares(
        int256 collateral,
        int256 borrow,
        uint256 maxTotalAssetsInUnderlying,
        uint256 supplyAfterFee,
        uint256 totalAssets,
        uint256 borrowPrice
    ) internal pure returns (uint256) {
        uint256 totalAssetsInUnderlying = uint256(collateral - borrow);

        if (totalAssetsInUnderlying >= maxTotalAssetsInUnderlying) {
            return 0;
        }

        // round down to assume less available space
        uint256 availableSpaceInShares = (maxTotalAssetsInUnderlying - totalAssetsInUnderlying).mulDivDown(
            Constants.ORACLE_DIVIDER, borrowPrice
        ).mulDivDown(supplyAfterFee, totalAssets);

        return availableSpaceInShares;
    }
}
