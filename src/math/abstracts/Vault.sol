// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintStateToData} from "src/math/abstracts/state_to_data/max/MaxDepositMintStateToData.sol";
import {MaxWithdrawRedeemStateToData} from "src/math/abstracts/state_to_data/max/MaxWithdrawRedeemStateToData.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title Vault
 * @notice Contract contains common functionality for all max vault functions.
 */
abstract contract Vault is MaxDepositMintStateToData, MaxWithdrawRedeemStateToData {
    using UMulDiv for uint256;

    /**
     * @notice Calculates available space according to maxTotalAssetsInUnderlying
     * constant. Return value is in shares because shares represent real difference
     * in total assets after user operation
     */
    function getAvailableSpaceInShares(
        int256 collateral,
        int256 borrow,
        uint256 maxTotalAssetsInUnderlying,
        uint256 supplyAfterFee,
        uint256 totalAssets,
        uint256 borrowPrice,
        uint8 borrowTokenDecimals
    ) internal pure returns (uint256) {
        // casting to uint256 is safe because collateral is considered to be greater than borrow
        // forge-lint: disable-next-line(unsafe-typecast)
        uint256 totalAssetsInUnderlying = uint256(collateral - borrow);

        if (totalAssetsInUnderlying >= maxTotalAssetsInUnderlying) {
            return 0;
        }

        // round down to assume less available space
        uint256 availableSpaceInShares = (maxTotalAssetsInUnderlying - totalAssetsInUnderlying).mulDivDown(
            10 ** borrowTokenDecimals, borrowPrice
        ).mulDivDown(supplyAfterFee, totalAssets);

        return availableSpaceInShares;
    }
}
