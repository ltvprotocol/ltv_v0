// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {ILendingConnector} from "src/interfaces/connectors/ILendingConnector.sol";
import {IOracleConnector} from "src/interfaces/connectors/IOracleConnector.sol";
import {IWhitelistRegistry} from "src/interfaces/IWhitelistRegistry.sol";
import {ISlippageConnector} from "src/interfaces/connectors/ISlippageConnector.sol";
import {IModules} from "src/interfaces/IModules.sol";

/**
 * @title LTVState
 * @notice contract contains an entire state of the vault
 * except Ownable part (since it's inherited from OwnableUpgradeable)
 */
abstract contract LTVState {
    address public feeCollector;
    IERC20 public collateralToken;
    uint8 public collateralTokenDecimals;
    IERC20 public borrowToken;
    uint8 public borrowTokenDecimals;

    ILendingConnector public lendingConnector;
    ILendingConnector public vaultBalanceAsLendingConnector;
    IOracleConnector public oracleConnector;
    ISlippageConnector public slippageConnector;

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

    uint16 public maxSafeLtvDividend;
    uint16 public maxSafeLtvDivider;
    uint16 public minProfitLtvDividend;
    uint16 public minProfitLtvDivider;
    uint16 public targetLtvDividend;
    uint16 public targetLtvDivider;

    uint8 public decimals;
    uint8 public boolSlot;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(bytes4 => bool) public _isFunctionDisabled;
    string public name;
    string public symbol;

    bytes public lendingConnectorGetterData;
    bytes public oracleConnectorGetterData;
    bytes public slippageConnectorGetterData;
    bytes public vaultBalanceAsLendingConnectorGetterData;
}
