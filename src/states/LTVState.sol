// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {ILendingConnector} from "src/interfaces/ILendingConnector.sol";
import {IOracleConnector} from "src/interfaces/IOracleConnector.sol";
import {IWhitelistRegistry} from "src/interfaces/IWhitelistRegistry.sol";
import {ISlippageProvider} from "src/interfaces/ISlippageProvider.sol";
import {IModules} from "src/interfaces/IModules.sol";
import {TotalAssetsState} from "src/structs/state/vault/TotalAssetsState.sol";
import {MaxGrowthFeeState} from "src/structs/state/MaxGrowthFeeState.sol";
import {PreviewVaultState} from "src/structs/state/vault/PreviewVaultState.sol";
import {MaxDepositMintBorrowVaultState} from "src/structs/state/vault/MaxDepositMintBorrowVaultState.sol";
import {MaxWithdrawRedeemBorrowVaultState} from "src/structs/state/vault/MaxWithdrawRedeemBorrowVaultState.sol";
import {MaxDepositMintCollateralVaultState} from "src/structs/state/vault/MaxDepositMintCollateralVaultState.sol";
import {MaxWithdrawRedeemCollateralVaultState} from "src/structs/state/vault/MaxWithdrawRedeemCollateralVaultState.sol";
import {AuctionState} from "src/structs/state/AuctionState.sol";
import {PreviewLowLevelRebalanceState} from "src/structs/state/low_level/PreviewLowLevelRebalanceState.sol";

abstract contract LTVState {
    address public feeCollector;
    IERC20 public collateralToken;
    IERC20 public borrowToken;

    ILendingConnector public lendingConnector;
    ILendingConnector public vaultBalanceAsLendingConnector;
    IOracleConnector public oracleConnector;
    ISlippageProvider public slippageProvider;

    address public governor;
    address public guardian;
    address public emergencyDeleverager;

    IWhitelistRegistry public whitelistRegistry;
    IModules public modules;

    int256 public futureBorrowAssets;
    int256 public futureCollateralAssets;
    int256 public futureRewardBorrowAssets;
    int256 public futureRewardCollateralAssets;

    uint256 public baseTotalSupply;
    uint256 public maxTotalAssetsInUnderlying;
    uint256 public lastSeenTokenPrice;

    uint56 public startAuction;
    uint24 public auctionDuration;

    uint16 public maxGrowthFeeDividend;
    uint16 public maxGrowthFeeDivider;
    uint16 public maxDeleverageFeeDividend;
    uint16 public maxDeleverageFeeDivider;

    uint16 public maxSafeLTVDividend;
    uint16 public maxSafeLTVDivider;
    uint16 public minProfitLTVDividend;
    uint16 public minProfitLTVDivider;
    uint16 public targetLTVDividend;
    uint16 public targetLTVDivider;

    uint8 public decimals;
    uint8 public boolSlot;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(bytes4 => bool) public _isFunctionDisabled;
    string public name;
    string public symbol;
    bytes internal connectorGetterData;
}
