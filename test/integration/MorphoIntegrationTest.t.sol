// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {MorphoConnector} from "../../src/connectors/lending_connectors/MorphoConnector.sol";
import {MorphoOracleConnector} from "../../src/connectors/oracle_connectors/MorphoOracleConnector.sol";
import {VaultBalanceAsLendingConnector} from
    "../../src/connectors/lending_connectors/VaultBalanceAsLendingConnector.sol";
import {IMorphoBlue} from "../../src/connectors/lending_connectors/interfaces/IMorphoBlue.sol";
import {IMorphoOracle} from "../../src/connectors/oracle_connectors/interfaces/IMorphoOracle.sol";
import {LTV} from "../../src/elements/LTV.sol";
import "forge-std/interfaces/IERC20.sol";
import {StateInitData} from "../../src/structs/state/StateInitData.sol";
import {ConstantSlippageProvider} from "../../src/connectors/slippage_providers/ConstantSlippageProvider.sol";
import {ModulesProvider, ModulesState} from "../../src/elements/ModulesProvider.sol";
import {AuctionModule, IAuctionModule} from "../../src/elements/AuctionModule.sol";
import {ERC20Module, IERC20Module} from "../../src/elements/ERC20Module.sol";
import {CollateralVaultModule, ICollateralVaultModule} from "../../src/elements/CollateralVaultModule.sol";
import {BorrowVaultModule, IBorrowVaultModule} from "../../src/elements/BorrowVaultModule.sol";
import {LowLevelRebalanceModule, ILowLevelRebalanceModule} from "../../src/elements/LowLevelRebalanceModule.sol";
import {AdministrationModule, IAdministrationModule} from "../../src/elements/AdministrationModule.sol";
import {ILendingConnector} from "../../src/interfaces/ILendingConnector.sol";
import {IOracleConnector} from "../../src/interfaces/IOracleConnector.sol";
import {IInitializeModule} from "../../src/interfaces/reads/IInitializeModule.sol";
import {InitializeModule} from "../../src/elements/InitializeModule.sol";

contract MorphoIntegrationTest is Test {
    address constant MORPHO_BLUE = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address constant MORPHO_ORACLE = 0xbD60A6770b27E084E8617335ddE769241B0e71D8;
    address constant IRM = 0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC;

    IMorphoBlue.MarketParams public marketParams;
    MorphoConnector public morphoLendingConnector;
    MorphoOracleConnector public morphoOracleConnector;
    LTV public ltv;
    IERC20 public weth;
    IERC20 public wsteth;
    ConstantSlippageProvider public slippageProvider;
    ModulesProvider public modulesProvider;

    address public user;

    function setUp() public {
        vm.createSelectFork(vm.envString("RPC_MAINNET"), 22769382);

        user = makeAddr("user");

        marketParams = IMorphoBlue.MarketParams({
            loanToken: WETH,
            collateralToken: WSTETH,
            oracle: MORPHO_ORACLE,
            irm: IRM,
            lltv: 945000000000000000
        });

        morphoLendingConnector = new MorphoConnector();
        morphoOracleConnector = new MorphoOracleConnector(IMorphoOracle(MORPHO_ORACLE));
        slippageProvider = new ConstantSlippageProvider(10 ** 16, 10 ** 16, address(this));

        weth = IERC20(WETH);
        wsteth = IERC20(WSTETH);

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

        StateInitData memory stateInitData = StateInitData({
            name: "123",
            symbol: "123",
            decimals: 18,
            collateralToken: WSTETH,
            borrowToken: WETH,
            feeCollector: address(this),
            maxSafeLTVDividend: 8,
            maxSafeLTVDivider: 10,
            minProfitLTVDividend: 5,
            minProfitLTVDivider: 10,
            targetLTVDividend: 75,
            targetLTVDivider: 100,
            lendingConnector: ILendingConnector(address(morphoLendingConnector)),
            oracleConnector: IOracleConnector(address(morphoOracleConnector)),
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
            lendingConnectorData: abi.encode(MORPHO_ORACLE, IRM, 945000000000000000, keccak256(abi.encode(marketParams)))
        });

        ltv = new LTV();
        ltv.initialize(stateInitData, modulesProvider);

        deal(WETH, address(this), 100 ether);
        deal(WSTETH, address(this), 100 ether);
        weth.approve(address(ltv), 100 ether);
        wsteth.approve(address(ltv), 100 ether);

        ltv.executeLowLevelRebalanceShares(10 ether);

        deal(WETH, user, 100 ether);
        deal(WSTETH, user, 100 ether);
    }

    function test_MorphoConnectorSet() public view {
        assertEq(address(ltv.borrowToken()), WETH);
        assertEq(address(ltv.collateralToken()), WSTETH);
    }

    function test_MorphoConnectorConfigs() public view {
        assertEq(address(ltv.getLendingConnector()), address(morphoLendingConnector));
        assertEq(address(ltv.oracleConnector()), address(morphoOracleConnector));
        assertEq(address(ltv.borrowToken()), WETH);
        assertEq(address(ltv.collateralToken()), WSTETH);
    }

    function test_MorphoConnectorMaxDepositBorrow() public {
        uint256 maxDeposit = ltv.maxDeposit(user);
        vm.startPrank(user);

        weth.approve(address(ltv), maxDeposit);
        ltv.deposit(maxDeposit, user);

        vm.stopPrank();
    }

    function test_MorphoConnectorMaxMint() public {
        uint256 maxMint = ltv.maxMint(user);
        uint256 neededToMint = ltv.previewMint(maxMint);

        vm.startPrank(user);
        weth.approve(address(ltv), neededToMint);
        ltv.mint(maxMint, user);
        vm.stopPrank();
    }

    function test_MorphoConnectorMaxWithdraw() public {
        uint256 maxDeposit = ltv.maxDeposit(user);

        vm.startPrank(user);
        weth.approve(address(ltv), maxDeposit);
        ltv.deposit(maxDeposit, user);

        uint256 maxWithdraw = ltv.maxWithdraw(user);
        ltv.withdraw(maxWithdraw, user, user);
        vm.stopPrank();
    }

    function test_MorphoConnectorMaxRedeem() public {
        uint256 maxDeposit = ltv.maxDeposit(user);

        vm.startPrank(user);
        weth.approve(address(ltv), maxDeposit);
        ltv.deposit(maxDeposit, user);

        uint256 maxRedeem = ltv.maxRedeem(user);
        ltv.redeem(maxRedeem, user, user);
        vm.stopPrank();
    }

    function test_MorphoConnectorMaxDepositCollateral() public {
        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);

        vm.startPrank(user);
        wsteth.approve(address(ltv), type(uint256).max);
        ltv.depositCollateral(maxDepositCollateral, user);
        vm.stopPrank();
    }

    function test_MorphoConnectorMaxMintCollateral() public {
        uint256 maxMintCollateral = ltv.maxMintCollateral(user);

        vm.startPrank(user);
        wsteth.approve(address(ltv), type(uint256).max);
        ltv.mintCollateral(maxMintCollateral, user);
        vm.stopPrank();
    }

    function test_MorphoConnectorMaxWithdrawCollateral() public {
        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);

        vm.startPrank(user);
        wsteth.approve(address(ltv), maxDepositCollateral);
        ltv.depositCollateral(maxDepositCollateral, user);

        uint256 maxWithdrawCollateral = ltv.maxWithdrawCollateral(user);
        ltv.withdrawCollateral(maxWithdrawCollateral, user, user);
        vm.stopPrank();
    }

    function test_MorphoConnectorMaxsRedeemCollateral() public {
        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);

        vm.startPrank(user);
        wsteth.approve(address(ltv), maxDepositCollateral);
        ltv.depositCollateral(maxDepositCollateral, user);

        uint256 maxRedeemCollateral = ltv.maxRedeemCollateral(user);
        ltv.redeemCollateral(maxRedeemCollateral, user, user);
        vm.stopPrank();
    }

    function test_MorphoConnectorIntegration() public view {
        assertEq(address(ltv.borrowToken()), WETH);
        assertEq(address(ltv.collateralToken()), WSTETH);

        uint256 collateralPrice = morphoOracleConnector.getPriceCollateralOracle();
        uint256 borrowPrice = morphoOracleConnector.getPriceBorrowOracle();
        assertGt(collateralPrice, 0);
        assertEq(borrowPrice, 1e18);

        assertEq(address(ltv.getLendingConnector()), address(morphoLendingConnector));
        assertEq(address(ltv.oracleConnector()), address(morphoOracleConnector));
    }

    function test_MorphoConnectorDeposit() public {
        vm.startPrank(user);

        weth.approve(address(ltv), 1 ether);
        uint256 shares = ltv.deposit(1 ether, user);

        vm.stopPrank();
        assertEq(shares, 961165048543689320);
    }

    function test_MorphoConnectorMint() public {
        vm.startPrank(user);

        weth.approve(address(ltv), 1040404040404040405);
        uint256 givenBorrowTokens = ltv.mint(1 ether, user);

        vm.stopPrank();

        assertEq(givenBorrowTokens, 1040404040404040405);
    }

    function test_MorphoConnectorWithdraw() public {
        uint256 maxDeposit = ltv.maxDeposit(user);
        vm.startPrank(user);
        weth.approve(address(ltv), maxDeposit);
        ltv.deposit(maxDeposit, user);

        uint256 shares = ltv.withdraw(1 ether, user, user);

        vm.stopPrank();
        assertEq(shares, 1 ether);
    }

    function test_MorphoConnectorRedeem() public {
        uint256 maxDeposit = ltv.maxDeposit(user);

        vm.startPrank(user);

        weth.approve(address(ltv), maxDeposit);
        ltv.deposit(maxDeposit, user);

        uint256 assetsReceived = ltv.redeem(1 ether, user, user);

        vm.stopPrank();
        assertEq(assetsReceived, 1 ether);
    }

    function test_MorphoConnectorDepositCollateral() public {
        vm.startPrank(user);

        wsteth.approve(address(ltv), 1 ether);
        uint256 shares = ltv.depositCollateral(1 ether, user);

        vm.stopPrank();
        assertEq(shares, 1171155094625884439);
    }

    function test_MorphoConnectorMintCollateral() public {
        vm.startPrank(user);

        wsteth.approve(address(ltv), ltv.previewMintCollateral(1 ether));
        uint256 givenCollateralToken = ltv.mintCollateral(1 ether, user);

        vm.stopPrank();

        assertEq(givenCollateralToken, 853857874664705719);
    }

    function test_MorphoConnectorWithdrawCollateral() public {
        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);

        vm.startPrank(user);

        wsteth.approve(address(ltv), maxDepositCollateral);
        ltv.depositCollateral(maxDepositCollateral, user);

        uint256 shares = ltv.withdrawCollateral(1 ether, user, user);

        vm.stopPrank();

        assertEq(shares, 1206289747464660974);
        assertEq(shares, ltv.convertToSharesCollateral(1 ether) + 1);
    }

    function test_MorphoConnectorRedeemCollateral() public {
        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);

        vm.startPrank(user);

        wsteth.approve(address(ltv), maxDepositCollateral);
        ltv.depositCollateral(maxDepositCollateral, user);

        uint256 assetsReceived = ltv.redeemCollateral(1 ether, user, user);

        vm.stopPrank();

        assertEq(assetsReceived, 828988227829811374);
        assertEq(assetsReceived, ltv.convertToAssetsCollateral(1 ether) - 1);
    }
}
