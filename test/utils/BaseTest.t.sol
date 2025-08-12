// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../src/dummy/DummyOracle.sol";
import "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {MockDummyLending} from "./MockDummyLending.t.sol";
import "./DummyLTV.t.sol";
import "../../src/Constants.sol";
import "../../src/dummy/DummyLendingConnector.sol";
import "../../src/dummy/DummyOracleConnector.sol";
import "../../src/connectors/slippage_providers/ConstantSlippageProvider.sol";
import "../../src/connectors/lending_connectors/VaultBalanceAsLendingConnector.sol";
import "../../src/timelock/Timelock.sol";
import {ILTV} from "../../src/interfaces/ILTV.sol";
import {IAdministrationErrors} from "../../src/errors/IAdministrationErrors.sol";

import {AuctionModule} from "../../src/elements/AuctionModule.sol";
import {ERC20Module} from "../../src/elements/ERC20Module.sol";
import {CollateralVaultModule} from "../../src/elements/CollateralVaultModule.sol";
import {BorrowVaultModule} from "../../src/elements/BorrowVaultModule.sol";
import {LowLevelRebalanceModule} from "../../src/elements/LowLevelRebalanceModule.sol";
import {AdministrationModule} from "../../src/elements/AdministrationModule.sol";
import {InitializeModule} from "../../src/elements/InitializeModule.sol";

import "../../src/elements/ModulesProvider.sol";

struct BaseTestInit {
    address owner;
    address guardian;
    address governor;
    address emergencyDeleverager;
    address feeCollector;
    int256 futureBorrow;
    int256 futureCollateral;
    int256 auctionReward;
    uint256 startAuction;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
    uint256 maxTotalAssetsInUnderlying;
    uint256 collateralAssets;
    uint256 borrowAssets;
    uint128 maxSafeLTV;
    uint128 minProfitLTV;
    uint128 targetLTV;
    uint256 maxGrowthFee;
    uint256 collateralPrice;
    uint256 borrowPrice;
    uint256 maxDeleverageFee;
    uint256 zeroAddressTokens;
}

struct DefaultTestData {
    address owner;
    address guardian;
    address governor;
    address emergencyDeleverager;
    address feeCollector;
}

contract BaseTest is Test {
    DummyLTV public ltv;
    MockERC20 public collateralToken;
    MockERC20 public borrowToken;
    MockDummyLending public lendingProtocol;
    IDummyOracle public oracle;
    ModulesProvider public modulesProvider;
    ConstantSlippageProvider public slippageProvider;
    DummyOracleConnector public oracleConnector;
    DummyLendingConnector public lendingConnector;

    function initializeTest(BaseTestInit memory init) internal {
        vm.assume(init.owner != address(0));
        vm.assume(init.guardian != address(0));
        vm.assume(init.governor != address(0));
        vm.assume(init.emergencyDeleverager != address(0));
        vm.assume(init.feeCollector != address(0));

        collateralToken = new MockERC20();
        collateralToken.initialize("Collateral", "COL", 18);
        borrowToken = new MockERC20();
        borrowToken.initialize("Borrow", "BOR", 18);

        lendingProtocol = new MockDummyLending(init.owner);
        oracle = IDummyOracle(new DummyOracle());
        slippageProvider = new ConstantSlippageProvider(init.collateralSlippage, init.borrowSlippage, init.owner);
        {
            ModulesState memory modulesState = ModulesState({
                administrationModule: IAdministrationModule(address(new AdministrationModule())),
                auctionModule: IAuctionModule(address(new AuctionModule())),
                erc20Module: IERC20Module(address(new ERC20Module())),
                collateralVaultModule: ICollateralVaultModule(address(new CollateralVaultModule())),
                borrowVaultModule: IBorrowVaultModule(address(new BorrowVaultModule())),
                lowLevelRebalanceModule: ILowLevelRebalanceModule(address(new LowLevelRebalanceModule())),
                initializeModule: IInitializeModule(address(new InitializeModule()))
            });
            modulesProvider = new ModulesProvider(modulesState);
            oracleConnector = new DummyOracleConnector(oracle);
            lendingConnector = new DummyLendingConnector(collateralToken, borrowToken, lendingProtocol);

            StateInitData memory initData = StateInitData({
                name: "Dummy LTV",
                symbol: "DLTV",
                decimals: 18,
                collateralToken: address(collateralToken),
                borrowToken: address(borrowToken),
                feeCollector: init.feeCollector,
                maxSafeLTV: init.maxSafeLTV,
                minProfitLTV: init.minProfitLTV,
                targetLTV: init.targetLTV,
                lendingConnector: lendingConnector,
                oracleConnector: oracleConnector,
                maxGrowthFee: init.maxGrowthFee,
                maxTotalAssetsInUnderlying: init.maxTotalAssetsInUnderlying,
                slippageProvider: slippageProvider,
                maxDeleverageFee: init.maxDeleverageFee,
                vaultBalanceAsLendingConnector: new VaultBalanceAsLendingConnector(collateralToken, borrowToken),
                owner: init.owner,
                guardian: init.guardian,
                governor: init.governor,
                emergencyDeleverager: init.emergencyDeleverager,
                lendingConnectorData: "",
                oracleConnectorData: abi.encode(address(collateralToken), address(borrowToken))
            });

            ltv = new DummyLTV();
            ltv.initialize(initData, modulesProvider);
        }

        vm.startPrank(init.owner);
        oracle.setAssetPrice(address(borrowToken), init.borrowPrice);
        oracle.setAssetPrice(address(collateralToken), init.collateralPrice);

        deal(address(borrowToken), address(lendingProtocol), type(uint128).max);
        deal(address(collateralToken), address(lendingProtocol), type(uint128).max);

        vm.roll(Constants.AMOUNT_OF_STEPS);
        ltv.setStartAuction(init.startAuction);
        ltv.setFutureBorrowAssets(init.futureBorrow);
        ltv.setFutureCollateralAssets(init.futureCollateral);

        if (init.futureBorrow < 0) {
            require(init.auctionReward >= 0);
            ltv.setFutureRewardBorrowAssets(init.auctionReward);
        } else {
            require(init.auctionReward <= 0);
            ltv.setFutureRewardCollateralAssets(init.auctionReward);
        }

        lendingProtocol.setSupplyBalance(address(collateralToken), init.collateralAssets);
        lendingProtocol.setBorrowBalance(address(borrowToken), init.borrowAssets);
        ltv.mintFreeTokens(init.zeroAddressTokens, address(0));
        vm.stopPrank();
    }

    modifier testWithPredefinedDefaultValues(DefaultTestData memory defaultData) {
        BaseTestInit memory initData = BaseTestInit({
            owner: defaultData.owner,
            guardian: defaultData.guardian,
            governor: defaultData.governor,
            emergencyDeleverager: defaultData.emergencyDeleverager,
            feeCollector: defaultData.feeCollector,
            futureBorrow: 0,
            futureCollateral: 0,
            auctionReward: 0,
            startAuction: 0,
            collateralSlippage: 10 ** 16,
            borrowSlippage: 10 ** 16,
            maxTotalAssetsInUnderlying: type(uint128).max,
            collateralAssets: 2 * 10 ** 18,
            borrowAssets: 3 * 10 ** 18,
            maxSafeLTV: 9 * 10 ** 17,
            minProfitLTV: 5 * 10 ** 17,
            targetLTV: 75 * 10 ** 16,
            maxGrowthFee: 2 * 10 ** 17,
            collateralPrice: 2 * 10 ** 18,
            borrowPrice: 10 ** 18,
            maxDeleverageFee: 2 * 10 ** 16,
            zeroAddressTokens: 10 ** 18
        });
        initializeTest(initData);
        _;
    }
}
