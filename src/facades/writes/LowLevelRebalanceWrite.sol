// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../interfaces/IModules.sol';
import '../../states/LTVState.sol';
import '../writes/CommonWrite.sol';

abstract contract LowLevelRebalanceWrite is LTVState, CommonWrite {
    function executeLowLevelRebalanceShares(int256 deltaShares) external returns (int256, int256) {
        _delegate(address(modules.lowLevelRebalance()), abi.encode(deltaShares));
    }

    function executeLowLevelRebalanceBorrow(int256 deltaBorrowAssets) external returns (int256, int256) {
        _delegate(address(modules.lowLevelRebalance()), abi.encode(deltaBorrowAssets));
    }

    function executeLowLevelRebalanceCollateral(int256 deltaCollateralAssets) external returns (int256, int256) {
        _delegate(address(modules.lowLevelRebalance()), abi.encode(deltaCollateralAssets));
    }

    function executeLowLevelRebalanceBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint) external returns (int256, int256) {
        _delegate(address(modules.lowLevelRebalance()), abi.encode(deltaBorrowAssets, isSharesPositiveHint));
    }

    function executeLowLevelRebalanceCollateralHint(int256 deltaCollateralAssets, bool isSharesPositiveHint) external returns (int256, int256) {
        _delegate(address(modules.lowLevelRebalance()), abi.encode(deltaCollateralAssets, isSharesPositiveHint));
    }
}