// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../interfaces/IModules.sol';
import '../../states/readers/ModulesAddressStateReader.sol';
import '../writes/CommonWrite.sol';

abstract contract LowLevelRebalanceWrite is ModulesAddressStateReader, CommonWrite {
    /// Input - the change in protocol shares
    function executeLowLevelRebalanceShares(int256 /*deltaShares*/) external returns (int256, int256) {
        _delegate(getModules().lowLevelRebalancerWrite());
    }

    /// Input - the change in protocol borrow assets
    function executeLowLevelRebalanceBorrow(int256 /*deltaBorrowAssets*/) external returns (int256, int256) {
        _delegate(getModules().lowLevelRebalancerWrite());
    }

    /// Input - the change in protocol collateral assets
    function executeLowLevelRebalanceCollateral(int256 /*deltaCollateralAssets*/) external returns (int256, int256) {
        _delegate(getModules().lowLevelRebalancerWrite());
    }

    /// Input - the change in protocol borrow assets, hint about shares direction
    function executeLowLevelRebalanceBorrowHint(int256 /*deltaBorrowAssets*/, bool /*isSharesPositiveHint*/) external returns (int256, int256) {
        _delegate(getModules().lowLevelRebalancerWrite());
    }

    /// Input - the change in protocol collateral assets, hint about shares direction
    function executeLowLevelRebalanceCollateralHint(
        int256 /*deltaCollateralAssets*/,
        bool /*isSharesPositiveHint*/
    ) external returns (int256, int256) {
        _delegate(getModules().lowLevelRebalancerWrite());
    }
}
