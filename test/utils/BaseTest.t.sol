// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {IDummyOracle} from "src/dummy/interfaces/IDummyOracle.sol";
import {IAuctionModule} from "src/interfaces/reads/IAuctionModule.sol";
import {IERC20Module} from "src/interfaces/reads/IERC20Module.sol";
import {ICollateralVaultModule} from "src/interfaces/reads/ICollateralVaultModule.sol";
import {IBorrowVaultModule} from "src/interfaces/reads/IBorrowVaultModule.sol";
import {ILowLevelRebalanceModule} from "src/interfaces/reads/ILowLevelRebalanceModule.sol";
import {IInitializeModule} from "src/interfaces/writes/IInitializeModule.sol";
import {IAdministrationModule} from "src/interfaces/reads/IAdministrationModule.sol";
import {StateInitData} from "src/structs/state/initialize/StateInitData.sol";
import {ModulesState} from "src/structs/state/common/ModulesState.sol";
import {DummyLTV} from "test/utils/DummyLTV.t.sol";
import {MockDummyLending} from "test/utils/MockDummyLending.t.sol";
import {DummyOracle} from "src/dummy/DummyOracle.sol";
import {DummyLendingConnector} from "src/dummy/DummyLendingConnector.sol";
import {DummyOracleConnector} from "src/dummy/DummyOracleConnector.sol";
import {ConstantSlippageConnector} from "src/connectors/slippage_connectors/ConstantSlippageConnector.sol";
import {VaultBalanceAsLendingConnector} from "src/connectors/lending_connectors/VaultBalanceAsLendingConnector.sol";
import {AuctionModule} from "src/elements/modules/AuctionModule.sol";
import {ERC20Module} from "src/elements/modules/ERC20Module.sol";
import {CollateralVaultModule} from "src/elements/modules/CollateralVaultModule.sol";
import {BorrowVaultModule} from "src/elements/modules/BorrowVaultModule.sol";
import {LowLevelRebalanceModule} from "src/elements/modules/LowLevelRebalanceModule.sol";
import {AdministrationModule} from "src/elements/modules/AdministrationModule.sol";
import {InitializeModule} from "src/elements/modules/InitializeModule.sol";
import {ModulesProvider} from "src/elements/ModulesProvider.sol";

struct BaseTestInit {
    address owner;
    address guardian;
    address governor;
    address emergencyDeleverager;
    address feeCollector;
    int256 futureBorrow;
    int256 futureCollateral;
    int256 auctionReward;
    uint56 startAuction;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
    uint256 maxTotalAssetsInUnderlying;
    uint256 collateralAssets;
    uint256 borrowAssets;
    uint16 maxSafeLtvDividend;
    uint16 maxSafeLtvDivider;
    uint16 minProfitLtvDividend;
    uint16 minProfitLtvDivider;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    uint16 maxGrowthFeeDividend;
    uint16 maxGrowthFeeDivider;
    uint256 collateralPrice;
    uint256 borrowPrice;
    uint16 maxDeleverageFeeDividend;
    uint16 maxDeleverageFeeDivider;
    uint256 zeroAddressTokens;
}

struct BaseTestInitWithSpecificDecimals {
    BaseTestInit baseTestInit;
    uint8 collateralTokenDecimals;
    uint8 borrowTokenDecimals;
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
    ConstantSlippageConnector public slippageConnector;
    DummyOracleConnector public oracleConnector;
    DummyLendingConnector public lendingConnector;

    function initializeTestWithSpecificDecimals(BaseTestInitWithSpecificDecimals memory init) internal {
        collateralToken = new MockERC20();
        collateralToken.initialize("Collateral", "COL", init.collateralTokenDecimals);
        borrowToken = new MockERC20();
        borrowToken.initialize("Borrow", "BOR", init.borrowTokenDecimals);
        _initializeTest(init.baseTestInit);
    }

    function initializeTest(BaseTestInit memory init) internal {
        collateralToken = new MockERC20();
        collateralToken.initialize("Collateral", "COL", 18);
        borrowToken = new MockERC20();
        borrowToken.initialize("Borrow", "BOR", 18);
        _initializeTest(init);
    }

    function _initializeTest(BaseTestInit memory init) private {
        vm.assume(init.owner != address(0));
        vm.assume(init.guardian != address(0));
        vm.assume(init.governor != address(0));
        vm.assume(init.emergencyDeleverager != address(0));
        vm.assume(init.feeCollector != address(0));

        lendingProtocol = new MockDummyLending(init.owner);
        oracle = IDummyOracle(new DummyOracle());
        slippageConnector = new ConstantSlippageConnector();
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
            lendingConnector = new DummyLendingConnector(
                IERC20(address(collateralToken)), IERC20(address(borrowToken)), lendingProtocol
            );

            StateInitData memory initData = StateInitData({
                name: "Dummy LTV",
                symbol: "DLTV",
                collateralToken: address(collateralToken),
                borrowToken: address(borrowToken),
                feeCollector: init.feeCollector,
                maxSafeLtvDividend: init.maxSafeLtvDividend,
                maxSafeLtvDivider: init.maxSafeLtvDivider,
                minProfitLtvDividend: init.minProfitLtvDividend,
                minProfitLtvDivider: init.minProfitLtvDivider,
                targetLtvDividend: init.targetLtvDividend,
                targetLtvDivider: init.targetLtvDivider,
                lendingConnector: lendingConnector,
                oracleConnector: oracleConnector,
                maxGrowthFeeDividend: init.maxGrowthFeeDividend,
                maxGrowthFeeDivider: init.maxGrowthFeeDivider,
                maxTotalAssetsInUnderlying: init.maxTotalAssetsInUnderlying,
                slippageConnector: slippageConnector,
                maxDeleverageFeeDividend: init.maxDeleverageFeeDividend,
                maxDeleverageFeeDivider: init.maxDeleverageFeeDivider,
                vaultBalanceAsLendingConnector: new VaultBalanceAsLendingConnector(),
                owner: init.owner,
                guardian: init.guardian,
                governor: init.governor,
                emergencyDeleverager: init.emergencyDeleverager,
                auctionDuration: 1000,
                lendingConnectorData: "",
                oracleConnectorData: "",
                slippageConnectorData: abi.encode(init.collateralSlippage, init.borrowSlippage),
                vaultBalanceAsLendingConnectorData: ""
            });

            ltv = new DummyLTV();
            // Enable initializers
            vm.store(
                address(ltv), bytes32(0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00), bytes32(0)
            );
            ltv.initialize(initData, modulesProvider);
        }

        vm.startPrank(init.owner);
        oracle.setAssetPrice(address(borrowToken), init.borrowPrice);
        oracle.setAssetPrice(address(collateralToken), init.collateralPrice);

        deal(address(borrowToken), address(lendingProtocol), type(uint128).max);
        deal(address(collateralToken), address(lendingProtocol), type(uint128).max);

        vm.roll(1000);
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
            maxSafeLtvDividend: 9,
            maxSafeLtvDivider: 10,
            minProfitLtvDividend: 5,
            minProfitLtvDivider: 10,
            targetLtvDividend: 75,
            targetLtvDivider: 100,
            maxGrowthFeeDividend: 1,
            maxGrowthFeeDivider: 5,
            collateralPrice: 2 * 10 ** 18,
            borrowPrice: 10 ** 18,
            maxDeleverageFeeDividend: 1,
            maxDeleverageFeeDivider: 50,
            zeroAddressTokens: 10 ** 18
        });
        initializeTest(initData);
        _;
    }
}
