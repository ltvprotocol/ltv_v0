// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {AuctionRead} from "src/facades/reads/AuctionRead.sol";
import {AuctionWrite} from "src/facades/writes/AuctionWrite.sol";
import {ERC20Read} from "src/facades/reads/ERC20Read.sol";
import {ERC20Write} from "src/facades/writes/ERC20Write.sol";
import {LowLevelRebalanceRead} from "src/facades/reads/LowLevelRebalanceRead.sol";
import {LowLevelRebalanceWrite} from "src/facades/writes/LowLevelRebalanceWrite.sol";
import {BorrowVaultRead} from "src/facades/reads/BorrowVaultRead.sol";
import {BorrowVaultWrite} from "src/facades/writes/BorrowVaultWrite.sol";
import {CollateralVaultRead} from "src/facades/reads/CollateralVaultRead.sol";
import {CollateralVaultWrite} from "src/facades/writes/CollateralVaultWrite.sol";
import {AdministrationWrite} from "src/facades/writes/AdministrationWrite.sol";
import {InitializeWrite} from "src/facades/writes/InitializeWrite.sol";


/**
 * @title LTV
 * @notice Main facade of LTV protocol. This contract contains all the public function signatures of LTV protocol.
 * @dev Since beacon proxy needs to be used and code size of an entire protocol exceeds contract size limit, modules-facade
 * architecture was created. It uses beacon proxy and uses facade contract as destination. Since facade has every
 * function signature, block explorer is able to show all the public functions of LTV protocol.
 * 
 * Facade has only routing role in this architecture. All the logic of LTV protocol is implemented in modules.
 * When facade receives a call, it delegates it to the corresponding module.
 * Modules are separated into different contracts to split code size.
 * Every single module is responsible for its own part of logic.
 * Unlike the modules, only one instance of facade is deployed and it has access to all the modules.
 * 
 * This contract inherits from multiple read/write facades, each handling specific protocol functionality:
 * - Auction operations (read/write)
 * - ERC20 token operations (read/write) 
 * - Low-level rebalancing (read/write)
 * - Borrow vault operations (read/write)
 * - Collateral vault operations (read/write)
 * - Administration and initialization operations
 */
contract LTV is
    AuctionRead,
    AuctionWrite,
    ERC20Read,
    ERC20Write,
    LowLevelRebalanceRead,
    LowLevelRebalanceWrite,
    BorrowVaultRead,
    BorrowVaultWrite,
    CollateralVaultRead,
    CollateralVaultWrite,
    AdministrationWrite,
    InitializeWrite
{
    constructor() {
        _disableInitializers();
    }
}
