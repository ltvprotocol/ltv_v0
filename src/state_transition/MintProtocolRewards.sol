// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MintProtocolRewardsData} from "src/structs/data/MintProtocolRewardsData.sol";
import {Constants} from "src/Constants.sol";
import {ERC20} from "src/state_transition/ERC20.sol";
import {uMulDiv} from "src/utils/MulDiv.sol";

abstract contract MintProtocolRewards is ERC20 {
    using uMulDiv for uint256;

    function _mintProtocolRewards(MintProtocolRewardsData memory data) internal {
        // in both cases rounding conflict between HODLer and fee collector. Resolve it in favor of HODLer
        if (data.deltaProtocolFutureRewardBorrow < 0) {
            uint256 shares = uint256(-data.deltaProtocolFutureRewardBorrow).mulDivDown(
                Constants.ORACLE_DIVIDER, data.assetPrice
            ).mulDivDown(data.supply, data.totalAppropriateAssets);
            _mint(feeCollector, shares);
        } else if (data.deltaProtocolFutureRewardCollateral > 0) {
            _mint(
                feeCollector,
                uint256(data.deltaProtocolFutureRewardCollateral).mulDivDown(Constants.ORACLE_DIVIDER, data.assetPrice)
                    .mulDivDown(data.supply, data.totalAppropriateAssets)
            );
        }
    }
}
