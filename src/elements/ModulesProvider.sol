// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/structs/state/ModulesState.sol';
import 'src/interfaces/IModules.sol';

contract ModulesProvider is IModules {
    constructor(ModulesState memory state) {
        borrowVaultsRead = state.borrowVaultsRead;
        collateralVaultsRead = state.collateralVaultsRead;
        lowLevelRebalancerRead = state.lowLevelRebalancerRead;
        auctionRead = state.auctionRead;

        borrowVaultsWrite = state.borrowVaultsWrite;
        collateralVaultsWrite = state.collateralVaultsWrite;
        erc20 = state.erc20;
        lowLevelRebalancerWrite = state.lowLevelRebalancerWrite;
        auctionWrite = state.auctionWrite;
        administration = state.administration;
        initializeWrite = state.initializeWrite;
    }

    IBorrowVaultRead public borrowVaultsRead;
    ICollateralVaultRead public collateralVaultsRead;
    ILowLevelRebalanceRead public lowLevelRebalancerRead;
    IAuctionRead public auctionRead;

    address public borrowVaultsWrite;
    address public collateralVaultsWrite;
    IERC20Read public erc20;
    address public lowLevelRebalancerWrite;
    address public auctionWrite;
    IAdministration public administration;
    address public initializeWrite;
}
