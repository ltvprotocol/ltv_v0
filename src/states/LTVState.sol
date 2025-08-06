// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../interfaces/ILendingConnector.sol";
import "../interfaces/IOracleConnector.sol";
import "../interfaces/IWhitelistRegistry.sol";
import "../interfaces/ISlippageProvider.sol";
import "../interfaces/IModules.sol";
import "forge-std/interfaces/IERC20.sol";
import "../structs/state/vault/TotalAssetsState.sol";
import "../structs/state/MaxGrowthFeeState.sol";
import "../structs/state/vault/PreviewVaultState.sol";
import "../structs/state/vault/MaxDepositMintBorrowVaultState.sol";
import "../structs/state/vault/MaxWithdrawRedeemBorrowVaultState.sol";
import "../structs/state/vault/MaxDepositMintCollateralVaultState.sol";
import "../structs/state/vault/MaxWithdrawRedeemCollateralVaultState.sol";
import "../structs/state/AuctionState.sol";
import "../structs/state/low_level/PreviewLowLevelRebalanceState.sol";
import "../structs/state/low_level/MaxLowLevelRebalanceSharesState.sol";
import "../structs/state/low_level/MaxLowLevelRebalanceBorrowStateData.sol";
import "../structs/state/low_level/MaxLowLevelRebalanceCollateralStateData.sol";
import "../structs/state/low_level/ExecuteLowLevelRebalanceState.sol";
abstract contract LTVState {
    address public feeCollector;
    address public collateralToken;
    address public borrowToken;

    address public lendingConnector;
    address public vaultBalanceAsLendingConnector;
    address public oracleConnector;
    address public slippageProvider;

    address public governor;
    address public guardian;
    address public emergencyDeleverager;

    address public whitelistRegistry;
    address public modules;

    int256 public futureBorrowAssets;
    int256 public futureCollateralAssets;
    int256 public futureRewardBorrowAssets;
    int256 public futureRewardCollateralAssets;

    uint256 public baseTotalSupply;
    uint256 public maxTotalAssetsInUnderlying;
    uint256 public lastSeenTokenPrice;

    uint64 public startAuction;

    uint24 public maxGrowthFeex23;
    uint24 public maxDeleverageFeex23;
    
    uint16 public maxSafeLTV;
    uint16 public maxSafeLTVDivider;
    uint16 public minProfitLTV;
    uint16 public minProfitLTVDivider;
    uint16 public targetLTV;
    uint16 public targetLTVDivider;
    
    uint8 public decimals;

    bool public isDepositDisabled;
    bool public isWithdrawDisabled;
    bool public isWhitelistActivated;
    bool public isVaultDeleveraged;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(bytes4 => bool) public _isFunctionDisabled;
    string public name;
    string public symbol;
    bytes internal connectorGetterData;
}
