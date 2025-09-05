// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {ILendingConnector} from "src/interfaces/ILendingConnector.sol";
import {IOracleConnector} from "src/interfaces/IOracleConnector.sol";
import {IAuctionModule} from "src/interfaces/reads/IAuctionModule.sol";
import {IERC20Module} from "src/interfaces/reads/IERC20Module.sol";
import {ICollateralVaultModule} from "src/interfaces/reads/ICollateralVaultModule.sol";
import {IBorrowVaultModule} from "src/interfaces/reads/IBorrowVaultModule.sol";
import {ILowLevelRebalanceModule} from "src/interfaces/reads/ILowLevelRebalanceModule.sol";
import {IInitializeModule} from "src/interfaces/reads/IInitializeModule.sol";
import {StateInitData} from "src/structs/state/StateInitData.sol";
import {AaveV3Connector} from "src/connectors/lending_connectors/AaveV3Connector.sol";
import {AaveV3OracleConnector} from "src/connectors/oracle_connectors/AaveV3OracleConnector.sol";
import {ConstantSlippageProvider} from "src/connectors/slippage_providers/ConstantSlippageProvider.sol";
import {InitializeModule} from "src/elements/InitializeModule.sol";
import {ModulesProvider, ModulesState} from "src/elements/ModulesProvider.sol";
import {AuctionModule} from "src/elements/AuctionModule.sol";
import {ERC20Module} from "src/elements/ERC20Module.sol";
import {CollateralVaultModule} from "src/elements/CollateralVaultModule.sol";
import {BorrowVaultModule} from "src/elements/BorrowVaultModule.sol";
import {LowLevelRebalanceModule} from "src/elements/LowLevelRebalanceModule.sol";
import {AdministrationModule} from "src/elements/AdministrationModule.sol";
import {LTV} from "src/elements/LTV.sol";

contract AaveV3ConnectorTest is Test {
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    AaveV3Connector aaveLendingConnector;
    AaveV3OracleConnector aaveV3OracleConnector;
    ConstantSlippageProvider slippageProvider;
    ModulesProvider modulesProvider;
    IERC20 weth;
    IERC20 wsteth;
    LTV ltv;

    address user = address(0x123);

    function setUp() public {
        vm.createSelectFork(vm.envString("RPC_MAINNET"), 22769382);

        weth = IERC20(WETH);
        wsteth = IERC20(WSTETH);

        aaveLendingConnector = new AaveV3Connector(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
        aaveV3OracleConnector = new AaveV3OracleConnector(0x54586bE62E3c3580375aE3723C145253060Ca0C2);
        slippageProvider = new ConstantSlippageProvider();

        ModulesState memory modulesState = ModulesState({
            administrationModule: address(new AdministrationModule()),
            auctionModule: IAuctionModule(address(new AuctionModule())),
            erc20Module: IERC20Module(address(new ERC20Module())),
            collateralVaultModule: ICollateralVaultModule(address(new CollateralVaultModule())),
            borrowVaultModule: IBorrowVaultModule(address(new BorrowVaultModule())),
            lowLevelRebalanceModule: ILowLevelRebalanceModule(address(new LowLevelRebalanceModule())),
            initializeModule: IInitializeModule(address(new InitializeModule()))
        });

        modulesProvider = new ModulesProvider(modulesState);

        StateInitData memory stateInitData = StateInitData({
            name: "AAVE LTV",
            symbol: "ALTV",
            decimals: 18,
            collateralToken: WSTETH,
            borrowToken: WETH,
            feeCollector: address(this),
            maxSafeLtvDividend: 8,
            maxSafeLtvDivider: 10,
            minProfitLtvDividend: 5,
            minProfitLtvDivider: 10,
            targetLtvDividend: 75,
            targetLtvDivider: 100,
            lendingConnector: ILendingConnector(address(aaveLendingConnector)),
            oracleConnector: IOracleConnector(address(aaveV3OracleConnector)),
            maxGrowthFeeDividend: 1,
            maxGrowthFeeDivider: 5,
            maxTotalAssetsInUnderlying: type(uint128).max,
            slippageProvider: slippageProvider,
            maxDeleverageFeeDividend: 1,
            maxDeleverageFeeDivider: 20,
            vaultBalanceAsLendingConnector: ILendingConnector(address(0)),
            owner: address(this),
            guardian: address(this),
            governor: address(this),
            emergencyDeleverager: address(this),
            auctionDuration: 1000,
            lendingConnectorData: abi.encode(1),
            oracleConnectorData: "",
            slippageProviderData: abi.encode(10 ** 16, 10 ** 16),
            vaultBalanceAsLendingConnectorData: ""
        });

        ltv = new LTV();
        // Enable initializers
        vm.store(address(ltv), bytes32(0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00), bytes32(0));
        ltv.initialize(stateInitData, modulesProvider);

        deal(WETH, address(this), 100 ether);
        deal(WSTETH, address(this), 100 ether);
        weth.approve(address(ltv), 100 ether);
        wsteth.approve(address(ltv), 100 ether);

        ltv.executeLowLevelRebalanceShares(10 ether);

        deal(WETH, user, 100 ether);
        deal(WSTETH, user, 100 ether);
    }

    function test_AaveV3ConnectorConfigs() public view {
        assertEq(address(ltv.getLendingConnector()), address(aaveLendingConnector));
        assertEq(address(ltv.oracleConnector()), address(aaveV3OracleConnector));
        assertEq(address(ltv.borrowToken()), WETH);
        assertEq(address(ltv.collateralToken()), WSTETH);
    }

    function test_AaveV3ConnectorMaxDeposit() public {
        uint256 maxDeposit = ltv.maxDeposit(user);

        vm.startPrank(user);

        weth.approve(address(ltv), maxDeposit);
        ltv.deposit(maxDeposit, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorMaxMint() public {
        uint256 maxMint = ltv.maxMint(user);
        uint256 neededToMint = ltv.previewMint(maxMint);

        vm.startPrank(user);

        weth.approve(address(ltv), neededToMint);
        ltv.mint(maxMint, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorMaxWithdraw() public {
        uint256 maxDeposit = ltv.maxDeposit(user);

        vm.startPrank(user);

        weth.approve(address(ltv), maxDeposit);
        ltv.deposit(maxDeposit, user);

        uint256 maxWithdraw = ltv.maxWithdraw(user);
        ltv.withdraw(maxWithdraw, user, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorMaxRedeem() public {
        uint256 maxDeposit = ltv.maxDeposit(user);

        vm.startPrank(user);

        weth.approve(address(ltv), maxDeposit);
        ltv.deposit(maxDeposit, user);

        uint256 maxRedeem = ltv.maxRedeem(user);
        ltv.redeem(maxRedeem, user, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorMaxDepositCollateral() public {
        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);

        vm.startPrank(user);

        wsteth.approve(address(ltv), maxDepositCollateral);
        ltv.depositCollateral(maxDepositCollateral, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorMaxMintCollateral() public {
        uint256 maxMintCollateral = ltv.maxMintCollateral(user);
        uint256 neededToMint = ltv.previewMintCollateral(maxMintCollateral);

        vm.startPrank(user);

        wsteth.approve(address(ltv), neededToMint);
        ltv.mintCollateral(maxMintCollateral, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorMaxWithdrawCollateral() public {
        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);

        vm.startPrank(user);

        wsteth.approve(address(ltv), maxDepositCollateral);
        ltv.depositCollateral(maxDepositCollateral, user);

        uint256 maxWithdrawCollateral = ltv.maxWithdrawCollateral(user);
        ltv.withdrawCollateral(maxWithdrawCollateral, user, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorMaxRedeemCollateral() public {
        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);

        vm.startPrank(user);

        wsteth.approve(address(ltv), maxDepositCollateral);
        ltv.depositCollateral(maxDepositCollateral, user);

        uint256 maxRedeemCollateral = ltv.maxRedeemCollateral(user);
        ltv.redeemCollateral(maxRedeemCollateral, user, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorDeposit() public {
        vm.startPrank(user);

        weth.approve(address(ltv), 1 ether);
        uint256 shares = ltv.deposit(1 ether, user);

        vm.stopPrank();

        assertEq(shares, 961165048543689319);
    }

    function test_AaveV3ConnectorMint() public {
        vm.startPrank(user);

        weth.approve(address(ltv), 1040404040404040406);
        uint256 givenBorrowTokens = ltv.mint(1 ether, user);

        vm.stopPrank();

        assertEq(givenBorrowTokens, 1040404040404040406);
    }

    function test_AaveV3ConnectorWithdraw() public {
        uint256 maxDeposit = ltv.maxDeposit(user);

        vm.startPrank(user);

        weth.approve(address(ltv), maxDeposit);
        ltv.deposit(maxDeposit, user);

        uint256 shares = ltv.withdraw(1 ether, user, user);

        vm.stopPrank();

        assertEq(shares, 1000000000000000001);
    }

    function test_AaveV3ConnectorRedeem() public {
        uint256 maxDeposit = ltv.maxDeposit(user);

        vm.startPrank(user);

        weth.approve(address(ltv), maxDeposit);
        ltv.deposit(maxDeposit, user);

        uint256 assetsReceived = ltv.redeem(1 ether, user, user);

        vm.stopPrank();

        assertEq(assetsReceived, 999999999999999999);
    }

    function test_AaveV3ConnectorDepositCollateral() public {
        vm.startPrank(user);

        wsteth.approve(address(ltv), 1 ether);
        uint256 shares = ltv.depositCollateral(1 ether, user);

        vm.stopPrank();

        assertEq(shares, 1171155094624127041);
    }

    function test_AaveV3ConnectorMintCollateral() public {
        vm.startPrank(user);

        wsteth.approve(address(ltv), 853857874673156914);
        uint256 givenCollateralToken = ltv.mintCollateral(1 ether, user);

        vm.stopPrank();

        assertEq(givenCollateralToken, 853857874665986989);
    }

    function test_AaveV3ConnectorWithdrawCollateral() public {
        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);

        vm.startPrank(user);

        wsteth.approve(address(ltv), maxDepositCollateral);
        ltv.depositCollateral(maxDepositCollateral, user);

        uint256 shares = ltv.withdrawCollateral(1 ether, user, user);

        vm.stopPrank();

        assertEq(shares, 1206289747462850855);
    }

    function test_AaveV3ConnectorRedeemCollateral() public {
        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);

        vm.startPrank(user);

        wsteth.approve(address(ltv), maxDepositCollateral);
        ltv.depositCollateral(maxDepositCollateral, user);

        uint256 assetsReceived = ltv.redeemCollateral(1 ether, user, user);

        vm.stopPrank();

        assertEq(assetsReceived, 828988227831055327);
    }
}
