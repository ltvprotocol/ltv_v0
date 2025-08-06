// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../facades/reads/AuctionRead.sol";
import "../facades/writes/AuctionWrite.sol";
import "../facades/reads/ERC20Read.sol";
import "../facades/writes/ERC20Write.sol";
import "../facades/reads/LowLevelRebalanceRead.sol";
import "../facades/writes/LowLevelRebalanceWrite.sol";
import "../facades/reads/BorrowVaultRead.sol";
import "../facades/writes/BorrowVaultWrite.sol";
import "../facades/reads/CollateralVaultRead.sol";
import "../facades/writes/CollateralVaultWrite.sol";
import "../facades/writes/AdministrationWrite.sol";
import "../facades/writes/InitializeWrite.sol";
import "src/state_reader/GetRealBorrowAssetsReader.sol";
import "src/state_reader/GetRealCollateralAssetsReader.sol";
import "src/state_reader/GetIsDepositDisabled.sol";
import "src/state_reader/GetIsWithdrawDisabled.sol";
import "src/state_reader/GetIsWhitelistActivated.sol";

contract LTV is
    GetIsWhitelistActivated,
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
    InitializeWrite,
    GetRealBorrowAssetsReader,
    GetRealCollateralAssetsReader,
    GetIsDepositDisabled,
    GetIsWithdrawDisabled
{}
