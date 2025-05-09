// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './Constants.sol';

import './Structs.sol';

import './utils/MulDiv.sol';
import './utils/UpgradeableOwnableWithGuardianAndGovernor.sol';
import './utils/UpgradeableOwnableWithEmergencyDeleverager.sol';

import 'forge-std/interfaces/IERC20.sol';

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';

import './interfaces/ILendingConnector.sol';
import './interfaces/IOracleConnector.sol';
import './interfaces/IWhitelistRegistry.sol';
import './interfaces/ISlippageProvider.sol';

abstract contract State is UpgradeableOwnableWithGuardianAndGovernor, UpgradeableOwnableWithEmergencyDeleverager, ReentrancyGuardUpgradeable {
    using uMulDiv for uint256;
    using sMulDiv for int256;

    error DepositIsDisabled();
    error WithdrawIsDisabled();

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
    
    ILendingConnector internal lendingConnector;
    bool isVaultDeleveraged;
    IOracleConnector public oracleConnector;

    uint256 internal lastSeenTokenPrice;
    uint256 internal maxGrowthFee;

    uint256 public maxTotalAssetsInUnderlying;

    mapping(bytes4 => bool) public _isFunctionDisabled;
    ISlippageProvider public slippageProvider;
    bool public isDepositDisabled;
    bool public isWithdrawDisabled;
    IWhitelistRegistry public whitelistRegistry;
    bool public isWhitelistActivated;

    uint256 public maxDeleverageFee;
    ILendingConnector public vaultBalanceAsLendingConnector;

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
        ISlippageProvider slippageProvider;
        uint256 maxDeleverageFee;
        ILendingConnector vaultBalanceAsLendingConnector;
    }

    error FunctionStopped(bytes4 functionSignature);
    error ReceiverNotWhitelisted(address receiver);

    modifier isFunctionAllowed() {
        _checkFunctionAllowed();
        _;
    }

    modifier isReceiverWhitelisted(address to) {
        _isReceiverWhitelisted(to);
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
        slippageProvider = initData.slippageProvider;
        maxDeleverageFee = initData.maxDeleverageFee;
        vaultBalanceAsLendingConnector = initData.vaultBalanceAsLendingConnector;

        lastSeenTokenPrice = 10 ** 18;
    }

    function totalSupply() public view returns (uint256) {
        // add 100 to avoid vault inflation attack
        return baseTotalSupply + 100;
    }

    function getPriceBorrowOracle() public view returns (uint256) {
        return oracleConnector.getPriceBorrowOracle();
    }

    function getPriceCollateralOracle() public view returns (uint256) {
        return oracleConnector.getPriceCollateralOracle();
    }

    function getRealBorrowAssets() public view returns (uint256) {
        return currentLendingConnector().getRealBorrowAssets();
    }

    function getRealCollateralAssets() public view returns (uint256) {
        return currentLendingConnector().getRealCollateralAssets();
    }

    function currentLendingConnector() public view returns (ILendingConnector) {
        return isVaultDeleveraged ? vaultBalanceAsLendingConnector : lendingConnector;
    }

    function _totalAssets(bool isDeposit) internal view virtual returns (uint256);

    function getAuctionStep() internal view returns (uint256) {
        uint256 auctionStep = block.number - startAuction;

        bool stuck = auctionStep > Constants.AMOUNT_OF_STEPS;

        if (stuck) {
            return Constants.AMOUNT_OF_STEPS;
        }

        return auctionStep;
    }

    function recoverConvertedAssets(bool isDeposit) internal view returns (ConvertedAssets memory) {
        // In case of deposit we have HODLer <=> depositor conflict, need to overestimate totalAssets() to underestimate user reward.
        // It's applied to every single rounding in this file.

        // in case of deposit we need to assume more assets in the protocol, so round borrow down
        int256 realBorrow = int256(getRealBorrowAssets().mulDiv(getPriceBorrowOracle(), Constants.ORACLE_DIVIDER, !isDeposit));

        // in case of deposit we need to assume more assets in the protocol, so round collateral up
        int256 realCollateral = int256(getRealCollateralAssets().mulDiv(getPriceCollateralOracle(), Constants.ORACLE_DIVIDER, isDeposit));

        // in case of deposit we need to assume more assets in the protocol, so round borrow down
        int256 futureBorrow = futureBorrowAssets.mulDiv(int256(getPriceBorrowOracle()), int256(Constants.ORACLE_DIVIDER), !isDeposit);

        // in case of deposit we need to assume more assets in the protocol, so round collateral up
        int256 futureCollateral = futureCollateralAssets.mulDiv(int256(getPriceCollateralOracle()), int256(Constants.ORACLE_DIVIDER), isDeposit);

        // in case of deposit we need to assume more assets in the protocol, so round borrow down
        int256 futureRewardBorrow = futureRewardBorrowAssets.mulDiv(int256(getPriceBorrowOracle()), int256(Constants.ORACLE_DIVIDER), !isDeposit);

        // in case of deposit we need to assume more assets pin the protocol, so round collateral up
        int256 futureRewardCollateral = futureRewardCollateralAssets.mulDiv(
            int256(getPriceCollateralOracle()),
            int256(Constants.ORACLE_DIVIDER),
            isDeposit
        );

        // Fee collector <=> Auction executor conflict. Resolve it in favor of the auction executor.
        int256 userFutureRewardBorrow = futureRewardBorrow.mulDivUp(int256(getAuctionStep()), int256(Constants.AMOUNT_OF_STEPS));

        // Fee collector <=> Auction executor conflict. Resolve it in favor of the auction executor.
        int256 userFutureRewardCollateral = futureRewardCollateral.mulDivDown(int256(getAuctionStep()), int256(Constants.AMOUNT_OF_STEPS));

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
            Prices({
                borrow: getPriceBorrowOracle(),
                collateral: getPriceCollateralOracle(),
                borrowSlippage: slippageProvider.borrowSlippage(),
                collateralSlippage: slippageProvider.collateralSlippage()
            });
    }

    function getAvailableSpaceInShares(ConvertedAssets memory convertedAssets, uint256 supply, bool isDeposit) internal view returns (uint256) {
        uint256 totalAssetsInUnderlying = uint256(convertedAssets.collateral - convertedAssets.borrow);

        if (totalAssetsInUnderlying >= maxTotalAssetsInUnderlying) {
            return 0;
        }

        // round down to assume less available space
        uint256 availableSpaceInShares = (maxTotalAssetsInUnderlying - totalAssetsInUnderlying)
            .mulDivDown(Constants.ORACLE_DIVIDER, getPriceBorrowOracle())
            .mulDivDown(supply, _totalAssets(isDeposit));

        return availableSpaceInShares;
    }

    function transferBorrowToken(address to, uint256 amount) internal isReceiverWhitelisted(to) {
        borrowToken.transfer(to, amount);
    }

    function transferCollateralToken(address to, uint256 amount) internal isReceiverWhitelisted(to) {
        collateralToken.transfer(to, amount);
    }

    function _checkFunctionAllowed() private view {
        require(!_isFunctionDisabled[msg.sig] || _msgSender() == owner() || _msgSender() == governor(), FunctionStopped(msg.sig));
    }

    function _isReceiverWhitelisted(address receiver) private view {
        require(!isWhitelistActivated || whitelistRegistry.isAddressWhitelisted(receiver), ReceiverNotWhitelisted(receiver));
    }
}
