// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import {ILendingConnector} from "../../src/interfaces/ILendingConnector.sol";
import {IOracleConnector} from "../../src/interfaces/IOracleConnector.sol";
import {IAaveOracle} from "../../src/connectors/oracle_connectors/interfaces/IAaveOracle.sol";
import {AaveV3Connector} from "../../src/connectors/lending_connectors/AaveV3Connector.sol";
import {AaveV3OracleConnector} from "../../src/connectors/oracle_connectors/AaveV3OracleConnector.sol";

import {ModulesProvider, ModulesState} from "../../src/elements/ModulesProvider.sol";
import {AuctionModule, IAuctionModule} from "../../src/elements/AuctionModule.sol";
import {ERC20Module, IERC20Module} from "../../src/elements/ERC20Module.sol";
import {CollateralVaultModule, ICollateralVaultModule} from "../../src/elements/CollateralVaultModule.sol";
import {BorrowVaultModule, IBorrowVaultModule} from "../../src/elements/BorrowVaultModule.sol";
import {LowLevelRebalanceModule, ILowLevelRebalanceModule} from "../../src/elements/LowLevelRebalanceModule.sol";
import {AdministrationModule, IAdministrationModule} from "../../src/elements/AdministrationModule.sol";
import {IInitializeModule} from "../../src/interfaces/reads/IInitializeModule.sol";
import {InitializeModule} from "../../src/elements/InitializeModule.sol";

import {StateInitData} from "../../src/structs/state/StateInitData.sol";
import {ConstantSlippageProvider} from "../../src/connectors/slippage_providers/ConstantSlippageProvider.sol";
import {LTV} from "../../src/elements/LTV.sol";

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

        aaveLendingConnector = new AaveV3Connector();
        aaveV3OracleConnector = new AaveV3OracleConnector(WSTETH, WETH);
        slippageProvider = new ConstantSlippageProvider(10 ** 16, 10 ** 16, address(this));

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
            name: "AAVE LTV",
            symbol: "ALTV",
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
            lendingConnectorData: abi.encode("")
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

        assertEq(shares, 961165048539872840);
    }

    function test_AaveV3ConnectorMint() public {
        vm.startPrank(user);

        weth.approve(address(ltv), 1040404040411684729);
        uint256 givenBorrowTokens = ltv.mint(1 ether, user);

        vm.stopPrank();

        assertEq(givenBorrowTokens, 1040404040411684729);
    }

    function test_AaveV3ConnectorWithdraw() public {
        uint256 maxDeposit = ltv.maxDeposit(user);

        vm.startPrank(user);

        weth.approve(address(ltv), maxDeposit);
        ltv.deposit(maxDeposit, user);

        uint256 shares = ltv.withdraw(1 ether, user, user);

        vm.stopPrank();

        assertEq(shares, 999999999999830446);
    }

    function test_AaveV3ConnectorRedeem() public {
        uint256 maxDeposit = ltv.maxDeposit(user);

        vm.startPrank(user);

        weth.approve(address(ltv), maxDeposit);
        ltv.deposit(maxDeposit, user);

        uint256 assetsReceived = ltv.redeem(1 ether, user, user);

        vm.stopPrank();

        assertEq(assetsReceived, 1000000000000000000);
    }

    function test_AaveV3ConnectorDepositCollateral() public {
        vm.startPrank(user);

        wsteth.approve(address(ltv), 1 ether);
        uint256 shares = ltv.depositCollateral(1 ether, user);

        vm.stopPrank();

        assertEq(shares, 1171155094622822850);
    }

    function test_AaveV3ConnectorMintCollateral() public {
        vm.startPrank(user);

        wsteth.approve(address(ltv), 853857874673156914);
        uint256 givenCollateralToken = ltv.mintCollateral(1 ether, user);

        vm.stopPrank();

        assertEq(givenCollateralToken, 853857874673156914);
    }

    function test_AaveV3ConnectorWithdrawCollateral() public {
        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);

        vm.startPrank(user);

        wsteth.approve(address(ltv), maxDepositCollateral);
        ltv.depositCollateral(maxDepositCollateral, user);

        uint256 shares = ltv.withdrawCollateral(1 ether, user, user);

        vm.stopPrank();

        assertEq(shares, 1206289747462433525);
    }

    function test_AaveV3ConnectorRedeemCollateral() public {
        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);

        vm.startPrank(user);

        wsteth.approve(address(ltv), maxDepositCollateral);
        ltv.depositCollateral(maxDepositCollateral, user);

        uint256 assetsReceived = ltv.redeemCollateral(1 ether, user, user);

        vm.stopPrank();

        assertEq(assetsReceived, 828988227831055328);
    }
}
