// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MintProtocolRewardsData} from "src/structs/data/vault/common/MintProtocolRewardsData.sol";
import {ERC20} from "src/state_transition/ERC20.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title MintProtocolRewards
 * @notice contract contains functionality to mint protocol rewards
 */
abstract contract MintProtocolRewards is ERC20 {
    using UMulDiv for uint256;

    /**
     * @dev If auction wasn't fully opened during cecb, cebc, ceccb or cecbc case calculations,
     * rewards which was allocated for auction but wasn't sent to the user go to the fee collector
     */
    function _mintProtocolRewards(MintProtocolRewardsData memory data) internal {
        uint256 rewardsInUnderlying =
            uint256(-data.deltaProtocolFutureRewardBorrow) + uint256(data.deltaProtocolFutureRewardCollateral);
        if (rewardsInUnderlying == 0) {
            return;
        }

        // in both cases rounding conflict between HODLer and fee collector. Resolve it in favor of HODLer
        uint256 shares = rewardsInUnderlying.mulDivDown(10 ** data.assetTokenDecimals, data.assetPrice).mulDivDown(
            data.supply, data.totalAppropriateAssets
        );
        _mint(feeCollector, shares);
    }
}
