// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './Constants.sol';

import './Structs.sol';

import './utils/MulDiv.sol';

import 'forge-std/interfaces/IERC20.sol';

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import './interfaces/ILendingConnector.sol';
import './interfaces/IOracleConnector.sol';

abstract contract State is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using uMulDiv for uint256;
    using sMulDiv for int256;

    address public feeCollector;

    int256 public futureBorrowAssets;
    int256 public futureCollateralAssets;
    int256 public futureRewardBorrowAssets;
    int256 public futureRewardCollateralAssets;
    uint256 public startAuction;

    // ERC 20 state
    uint256 public baseTotalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name;
    string public symbol;
    uint8 public decimals;

    IERC20 public collateralToken;
    IERC20 public borrowToken;

    uint128 public maxSafeLTV;
    uint128 public minProfitLTV;
    uint128 public targetLTV;

    ILendingConnector public lendingConnector;
    IOracleConnector public oracleConnector;

    uint256 internal lastSeenTokenPrice;
    uint256 internal maxGrowthFee;

    uint256 public maxTotalAssetsInUnderlying;

    mapping(bytes4 => bool) public _isFunctionDisabled;

    struct StateInitData {
        address collateralToken;
        address borrowToken;
        address feeCollector;
        uint128 maxSafeLTV;
        uint128 minProfitLTV;
        uint128 targetLTV;
        ILendingConnector lendingConnector;
        IOracleConnector oracleConnector;
        uint256 maxGrowthFee;
        uint256 maxTotalAssetsInUnderlying;
    }

    error FunctionNotAllowed();

    modifier isFunctionAllowed() {
        require(msg.sender == owner() || !_isFunctionDisabled[msg.sig], FunctionNotAllowed());
        _;
    }

    function __State_init(StateInitData memory initData) internal initializer {
        collateralToken = IERC20(initData.collateralToken);
        borrowToken = IERC20(initData.borrowToken);
        feeCollector = initData.feeCollector;
        maxSafeLTV = initData.maxSafeLTV;
        minProfitLTV = initData.minProfitLTV;
        targetLTV = initData.targetLTV;
        lendingConnector = initData.lendingConnector;
        oracleConnector = initData.oracleConnector;
        maxGrowthFee = initData.maxGrowthFee;
        maxTotalAssetsInUnderlying = initData.maxTotalAssetsInUnderlying;

        lastSeenTokenPrice = 10**18;
    }

    function totalAssets() public view virtual returns (uint256);

    function totalSupply() public view returns (uint256) {
        // add 100 to avoid vault inflation attack
        return baseTotalSupply + 100;
    }
    
    function getAuctionStep() internal view returns (uint256) {
        uint256 auctionStep = block.number - startAuction;

        bool stuck = auctionStep > Constants.AMOUNT_OF_STEPS;

        if (stuck) {
            return Constants.AMOUNT_OF_STEPS;
        }

        return auctionStep;
    }

    function recoverConvertedAssets() internal view returns (ConvertedAssets memory) {
        // borrow should be round up
        // because this is the amount that protocol should pay
        int256 realBorrow = int256(getRealBorrowAssets().mulDivUp(getPriceBorrowOracle(), Constants.ORACLE_DIVIDER));

        // collateral should be round down
        // because this is the amount that protocol owns
        int256 realCollateral = int256(getRealCollateralAssets().mulDivDown(getPriceCollateralOracle(), Constants.ORACLE_DIVIDER));

        // futureBorrow should be round down
        // because we want to minimize the amount that protocol will pay to the user
        // TODO: double check this with experts
        int256 futureBorrow = futureBorrowAssets.mulDivDown(int256(getPriceBorrowOracle()), int256(Constants.ORACLE_DIVIDER));

        // futureCollateral should be round up
        // because we want to maximize the amount that protocol will get from the user
        // TODO: double check this with experts
        int256 futureCollateral = futureCollateralAssets.mulDivUp(int256(getPriceCollateralOracle()), int256(Constants.ORACLE_DIVIDER));

        // futureRewardBorrow should be round down
        // because we want to minimize the amount that protocol will pay to the user
        // TODO: double check this with experts
        int256 futureRewardBorrow = futureRewardBorrowAssets.mulDivDown(int256(getPriceBorrowOracle()), int256(Constants.ORACLE_DIVIDER));

        // TODO: precheck futureRewardBorrow >= 0

        // futureRewardCollateral should be round up
        // because we want to maximize the amount that protocol will get from the user
        // TODO: double check this with experts
        int256 futureRewardCollateral = futureRewardCollateralAssets.mulDivUp(int256(getPriceCollateralOracle()), int256(Constants.ORACLE_DIVIDER));

        // TODO: precheck futureRewardCollateral <= 0

        // userFutureRewardBorrow should be round down
        // because we want to minimize the amount that protocol will pay to the user
        // TODO: double check this with experts
        int256 userFutureRewardBorrow = futureRewardBorrow.mulDivDown(int256(getAuctionStep()), int256(Constants.AMOUNT_OF_STEPS));

        // userFutureRewardCollateral should be round down
        // because we want to minimize the amount that protocol will pay to the user
        // TODO: double check this with experts
        int256 userFutureRewardCollateral = futureRewardCollateral.mulDivUp(int256(getAuctionStep()), int256(Constants.AMOUNT_OF_STEPS));

        int256 protocolFutureRewardBorrow = futureRewardBorrow - userFutureRewardBorrow;
        int256 protocolFutureRewardCollateral = futureRewardCollateral - userFutureRewardCollateral;

        int256 borrow = realBorrow + futureBorrow + futureRewardBorrow;
        int256 collateral = realCollateral + futureCollateral + futureRewardCollateral;

        return
            ConvertedAssets({
                borrow: borrow,
                collateral: collateral,
                realBorrow: realBorrow,
                realCollateral: realCollateral,
                futureBorrow: futureBorrow,
                futureCollateral: futureCollateral,
                futureRewardBorrow: futureRewardBorrow,
                futureRewardCollateral: futureRewardCollateral,
                protocolFutureRewardBorrow: protocolFutureRewardBorrow,
                protocolFutureRewardCollateral: protocolFutureRewardCollateral,
                userFutureRewardBorrow: userFutureRewardBorrow,
                userFutureRewardCollateral: userFutureRewardCollateral,
                auctionStep: int256(getAuctionStep())
            });
    }

    function getPrices() internal view virtual returns (Prices memory) {
        return
            Prices({borrow: getPriceBorrowOracle(), collateral: getPriceCollateralOracle(), borrowSlippage: 10 ** 16, collateralSlippage: 10 ** 16});
    }

    function getAvailableSpaceInShares(ConvertedAssets memory convertedAssets, uint256 supply) internal view returns (uint256) {
        uint256 totalAssetsInUnderlying = uint256(convertedAssets.collateral - convertedAssets.borrow);

        if (totalAssetsInUnderlying >= maxTotalAssetsInUnderlying) {
            return 0;
        }

        uint256 availableSpaceInShares = (maxTotalAssetsInUnderlying - totalAssetsInUnderlying)
            .mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle())
            .mulDivDown(supply, totalAssets());

        return availableSpaceInShares;
    }

    function getPriceBorrowOracle() public view returns (uint256) {
        return oracleConnector.getPriceBorrowOracle();
    }

    function getPriceCollateralOracle() public view returns (uint256) {
        return oracleConnector.getPriceCollateralOracle();
    }

    function getRealBorrowAssets() public view returns (uint256) {
        return lendingConnector.getRealBorrowAssets();
    }

    function getRealCollateralAssets() public view returns (uint256) {
        return lendingConnector.getRealCollateralAssets();
    }
}
