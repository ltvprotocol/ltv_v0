// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/public/low_level/preview/PreviewLowLevelRebalanceShares.sol';
import 'src/public/low_level/max/MaxLowLevelRebalanceShares.sol';
import 'src/state_transition/ApplyMaxGrowthFee.sol';
import 'src/math/PreviewLowLevelRebalanceStateToData.sol';
import 'src/state_transition/ExecuteLowLevelRebalance.sol';
import 'src/errors/ILowLevelRebalanceErrors.sol';

contract ExecuteLowLevelRebalanceShares is ExecuteLowLevelRebalance, PreviewLowLevelRebalanceShares, MaxLowLevelRebalanceShares, ApplyMaxGrowthFee, ILowLevelRebalanceErrors {

    function executeLowLevelRebalanceShares(int256 deltaShares) external isFunctionAllowed nonReentrant returns (int256, int256) {
        ExecuteLowLevelRebalanceState memory state = executeLowLevelRebalanceState();
        LowLevelRebalanceData memory data = previewLowLevelRebalanceStateToData(state.previewLowLevelRebalanceState, deltaShares >= 0);
        uint256 depositTotalAssets = deltaShares >= 0
            ? data.totalAssets
            : totalAssets(true, state.previewLowLevelRebalanceState.maxGrowthFeeState.totalAssetsState);
        int256 max = _maxLowLevelRebalanceShares(
            MaxLowLevelRebalanceSharesData({
                realCollateral: uint256(data.realCollateral),
                realBorrow: uint256(data.realBorrow),
                maxTotalAssetsInUnderlying: state.maxTotalAssetsInUnderlying,
                supplyAfterFee: data.supplyAfterFee,
                borrowPrice: data.borrowPrice,
                depositTotalAssets: depositTotalAssets
            })
        );
        require(deltaShares <= max, ExceedsLowLevelRebalanceMaxDeltaShares(deltaShares, max));

        (int256 deltaCollateral, int256 deltaBorrow, int256 deltaProtocolFutureReward) = _previewLowLevelRebalanceShares(deltaShares, data);

        applyMaxGrowthFee(data.supplyAfterFee, depositTotalAssets);

        executeLowLevelRebalance(deltaCollateral, deltaBorrow, deltaShares, deltaProtocolFutureReward);

        return (deltaCollateral, deltaBorrow);
    }
}
