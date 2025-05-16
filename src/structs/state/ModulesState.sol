// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/interfaces/reads/IBorrowVaultRead.sol';
import 'src/interfaces/reads/ICollateralVaultRead.sol';
import 'src/interfaces/reads/ILowLevelRebalanceRead.sol';
import 'src/interfaces/reads/IAuctionRead.sol';
import 'src/interfaces/reads/IAdministration.sol';
import 'src/interfaces/reads/IERC20Read.sol';

struct ModulesState {
    IBorrowVaultRead borrowVaultsRead;
    ICollateralVaultRead collateralVaultsRead;
    ILowLevelRebalanceRead lowLevelRebalancerRead;
    IAuctionRead auctionRead;
    IAdministration administration;
    IERC20Read erc20;
    address borrowVaultsWrite;
    address collateralVaultsWrite;
    address lowLevelRebalancerWrite;
    address auctionWrite;
    address initializeWrite;
}
