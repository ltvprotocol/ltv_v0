// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/structs/state/ModulesState.sol';
import 'src/interfaces/IModules.sol';

contract ModulesProvider is IModules {
    constructor(ModulesState memory state) {
        borrowVault = state.borrowVault;
        collateralVault = state.collateralVault;
        lowLevelRebalance = state.lowLevelRebalance;
        auction = state.auction;
        erc20 = state.erc20;
        administration = state.administration;
        initializeWrite = state.initializeWrite;
    }

    IBorrowVault public borrowVault;
    ICollateralVault public collateralVault;
    ILowLevelRebalance public lowLevelRebalance;
    IAuction public auction;
    IERC20Read public erc20;
    IAdministration public administration;
    address public initializeWrite;
}
