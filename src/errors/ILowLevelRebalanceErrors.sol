// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface ILowLevelRebalanceErrors {
    error ExceedsLowLevelRebalanceMaxDeltaCollateral(int256 deltaCollateral, int256 max);
    error ExceedsLowLevelRebalanceMaxDeltaBorrow(int256 deltaBorrow, int256 max);
    error ExceedsLowLevelRebalanceMaxDeltaShares(int256 deltaShares, int256 max);
    error ZeroTargetLTVDisablesBorrow();
}
