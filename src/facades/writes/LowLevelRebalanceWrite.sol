// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "src/states/LTVState.sol";
import {CommonWrite} from "src/facades/writes/CommonWrite.sol";

/**
 * @title LowLevelRebalanceWrite
 * @notice This contract contains all the write functions for the low level rebalance part of the LTV protocol.
 * Since signature and return data of the module and facade are the same, this contract easily delegates
 * calls to the low level rebalance module.
 */
abstract contract LowLevelRebalanceWrite is LTVState, CommonWrite {
    /**
     * @dev see ILTV.executeLowLevelRebalanceShares
     */
    function executeLowLevelRebalanceShares(int256 deltaShares) external returns (int256, int256) {
        _delegate(address(modules.lowLevelRebalanceModule()), abi.encode(deltaShares));
    }

    /**
     * @dev see ILTV.executeLowLevelRebalanceBorrow
     */
    function executeLowLevelRebalanceBorrow(int256 deltaBorrowAssets) external returns (int256, int256) {
        _delegate(address(modules.lowLevelRebalanceModule()), abi.encode(deltaBorrowAssets));
    }

    /**
     * @dev see ILTV.executeLowLevelRebalanceCollateral
     */
    function executeLowLevelRebalanceCollateral(int256 deltaCollateralAssets) external returns (int256, int256) {
        _delegate(address(modules.lowLevelRebalanceModule()), abi.encode(deltaCollateralAssets));
    }

    /**
     * @dev see ILTV.executeLowLevelRebalanceBorrowHint
     */
    function executeLowLevelRebalanceBorrowHint(int256 deltaBorrowAssets, bool isSharesPositiveHint)
        external
        returns (int256, int256)
    {
        _delegate(address(modules.lowLevelRebalanceModule()), abi.encode(deltaBorrowAssets, isSharesPositiveHint));
    }

    /**
     * @dev see ILTV.executeLowLevelRebalanceCollateralHint
     */
    function executeLowLevelRebalanceCollateralHint(int256 deltaCollateralAssets, bool isSharesPositiveHint)
        external
        returns (int256, int256)
    {
        _delegate(address(modules.lowLevelRebalanceModule()), abi.encode(deltaCollateralAssets, isSharesPositiveHint));
    }
}
