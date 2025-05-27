// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './TotalAssetsStateReader.sol';
import 'src/structs/state/MaxGrowthFeeState.sol';

contract MaxGrowthFeeStateReader is TotalAssetsStateReader {
    function maxGrowthFeeState() internal view returns (MaxGrowthFeeState memory) {
        return
            MaxGrowthFeeState({
                totalAssetsState: totalAssetsState(),
                maxGrowthFee: maxGrowthFee,
                supply: baseTotalSupply,
                lastSeenTokenPrice: lastSeenTokenPrice
            });
    }
}
