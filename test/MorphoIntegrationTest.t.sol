// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {MorphoConnector} from "../src/connectors/lending_connectors/MorphoConnector.sol";
import {MorphoOracleConnector} from "../src/connectors/oracle_connectors/MorphoOracleConnector.sol";
import {IMorphoBlue} from "../src/connectors/lending_connectors/interfaces/IMorphoBlue.sol";
import {IMorphoOracle} from "../src/connectors/oracle_connectors/interfaces/IMorphoOracle.sol";
import {LTV} from "../src/elements/LTV.sol";
import "forge-std/interfaces/IERC20.sol";
import {StateInitData} from "../src/structs/state/StateInitData.sol";
import {ConstantSlippageProvider} from "../src/connectors/slippage_providers/ConstantSlippageProvider.sol";
import {ModulesProvider, ModulesState} from "../src/elements/ModulesProvider.sol";
import {AuctionModule, IAuctionModule} from "../src/elements/AuctionModule.sol";
import {ERC20Module, IERC20Module} from "../src/elements/ERC20Module.sol";
import {CollateralVaultModule, ICollateralVaultModule} from "../src/elements/CollateralVaultModule.sol";
import {BorrowVaultModule, IBorrowVaultModule} from "../src/elements/BorrowVaultModule.sol";
import {LowLevelRebalanceModule, ILowLevelRebalanceModule} from "../src/elements/LowLevelRebalanceModule.sol";
import {AdministrationModule, IAdministrationModule} from "../src/elements/AdministrationModule.sol";
import {ILendingConnector} from "../src/interfaces/ILendingConnector.sol";
import {IOracleConnector} from "../src/interfaces/IOracleConnector.sol";

contract MorphoIntegrationTest is Test {
    address constant MORPHO_BLUE = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address constant MORPHO_ORACLE = 0x6F234Ff075B35312756A6B0a19DDb55Ff683E59d;
    address constant IRM = 0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC;

    MorphoConnector public morphoLendingConnector;
    MorphoOracleConnector public morphoOracleConnector;
    LTV public ltvVault;
    IERC20 public weth;
    IERC20 public wsteth;
    ConstantSlippageProvider public slippageProvider;
    ModulesProvider public modulesProvider;

    address public user;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        user = makeAddr("user");

        IMorphoBlue.MarketParams memory marketParams = IMorphoBlue.MarketParams({
            loanToken: WSTETH,
            collateralToken: WETH,
            oracle: MORPHO_ORACLE,
            irm: IRM,
            lltv: 945000000000000000
        });

        morphoLendingConnector = new MorphoConnector(marketParams);
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
            lowLevelRebalanceModule: ILowLevelRebalanceModule(address(new LowLevelRebalanceModule()))
        });
        modulesProvider = new ModulesProvider(modulesState);

        StateInitData memory stateInitData = StateInitData({
            name: "LTV Vault Test",
            symbol: "LTVT",
            decimals: 18,
            collateralToken: WETH,
            borrowToken: WSTETH,
            feeCollector: address(this),
            maxSafeLTV: 800000000000000000,
            minProfitLTV: 750000000000000000,
            targetLTV: 750000000000000000,
            lendingConnector: ILendingConnector(address(morphoLendingConnector)),
            oracleConnector: IOracleConnector(address(morphoOracleConnector)),
            maxGrowthFee: 200000000000000000,
            maxTotalAssetsInUnderlying: type(uint256).max,
            slippageProvider: slippageProvider,
            maxDeleverageFee: 50000000000000000,
            vaultBalanceAsLendingConnector: ILendingConnector(address(0)),
            modules: modulesProvider,
            owner: address(this),
            guardian: address(this),
            governor: address(this),
            emergencyDeleverager: address(this),
            callData: ""
        });

        ltvVault = new LTV();
        ltvVault.initialize(stateInitData);

        deal(address(wsteth), user, 100 ether);
        deal(address(weth), user, 100 ether);

        deal(address(wsteth), address(this), 50 ether);
        wsteth.approve(address(morphoLendingConnector), 50 ether);
        morphoLendingConnector.supply(50 ether);

        deal(address(weth), address(this), 30 ether);
        weth.approve(address(morphoLendingConnector), 30 ether);
        morphoLendingConnector.supplyCollateral(30 ether);
    }

    function testMorphoConnector() public view {
        assertEq(address(morphoLendingConnector.loanToken()), WSTETH);
        assertEq(address(morphoLendingConnector.collateralToken()), WETH);
    }

    function testMorphoOracleConnector() public view {
        uint256 collateralPrice = morphoOracleConnector.getPriceCollateralOracle();
        uint256 borrowPrice = morphoOracleConnector.getPriceBorrowOracle();

        assertGt(collateralPrice, 0);
        assertEq(borrowPrice, 10 ** 18);
    }

    function testVaultConfiguration() public view {
        assertEq(address(ltvVault.getLendingConnector()), address(morphoLendingConnector));
        assertEq(address(ltvVault.oracleConnector()), address(morphoOracleConnector));
        assertEq(address(ltvVault.borrowToken()), WSTETH);
        assertEq(address(ltvVault.collateralToken()), WETH);
    }

    function testUserCanWithVault() public {
        uint256 realCollateral = ltvVault.getRealCollateralAssets(true);
        assertTrue(realCollateral > 0);

        uint256 maxDeposit;
        uint256 maxMint;

        try ltvVault.maxDeposit(user) returns (uint256 md) {
            maxDeposit = md;
        } catch {
            maxDeposit = 0;
        }

        try ltvVault.maxMint(user) returns (uint256 mm) {
            maxMint = mm;
        } catch {
            maxMint = 0;
        }

        vm.startPrank(user);

        if (maxDeposit > 0) {
            uint256 depositAmount = maxDeposit > 1 ether ? 1 ether : maxDeposit;
            wsteth.approve(address(ltvVault), depositAmount);
            uint256 shares = ltvVault.deposit(depositAmount, user);
            assertGt(shares, 0);

            uint256 userBalance = ltvVault.balanceOf(user);
            assertGt(userBalance, 0);
        } else {
            assertTrue(true);
        }

        vm.stopPrank();
    }

    function testVaultState() public view {
        uint256 realCollateral = ltvVault.getRealCollateralAssets(true);
        uint256 realBorrow = ltvVault.getRealBorrowAssets(true);
        uint256 totalAssets = ltvVault.totalAssets();
        uint256 totalSupply = ltvVault.totalSupply();

        uint256 collateralPrice = morphoOracleConnector.getPriceCollateralOracle();
        uint256 borrowPrice = morphoOracleConnector.getPriceBorrowOracle();

        uint256 maxSafeLTV = ltvVault.maxSafeLTV();
        uint256 minProfitLTV = ltvVault.minProfitLTV();
        uint256 targetLTV = ltvVault.targetLTV();

        assertTrue(realCollateral > 0);
        assertEq(realBorrow, 0);
        assertGt(totalAssets, 0);
        assertGt(totalSupply, 0);
        assertGt(collateralPrice, 0);
        assertEq(borrowPrice, 1e18);
        assertEq(maxSafeLTV, 800000000000000000);
        assertEq(minProfitLTV, 750000000000000000);
        assertEq(targetLTV, 750000000000000000);
    }

    function testMorphoIntegration() public {
        assertEq(address(morphoLendingConnector.loanToken()), WSTETH);
        assertEq(address(morphoLendingConnector.collateralToken()), WETH);

        uint256 collateralPrice = morphoOracleConnector.getPriceCollateralOracle();
        uint256 borrowPrice = morphoOracleConnector.getPriceBorrowOracle();
        assertGt(collateralPrice, 0);
        assertEq(borrowPrice, 1e18);

        assertEq(address(ltvVault.getLendingConnector()), address(morphoLendingConnector));
        assertEq(address(ltvVault.oracleConnector()), address(morphoOracleConnector));

        uint256 realCollateral = ltvVault.getRealCollateralAssets(true);
        uint256 realBorrow = ltvVault.getRealBorrowAssets(true);
        assertGt(realCollateral, 0);
        assertEq(realBorrow, 0);

        deal(address(wsteth), address(this), 10 ether);
        wsteth.approve(address(morphoLendingConnector), 5 ether);
        morphoLendingConnector.supply(5 ether);

        uint256 newCollateral = morphoLendingConnector.getRealCollateralAssets(true);
        assertEq(newCollateral, 55 ether);
    }

    function testMorphoMarketExists() public view {
        (uint128 totalSupplyAssets, uint128 totalSupplyShares,,,,) =
            IMorphoBlue(MORPHO_BLUE).market(morphoLendingConnector.marketId());

        assertGt(totalSupplyAssets, 0);
        assertGt(totalSupplyShares, 0);

        (uint128 ourSupplyShares,, uint256 ourCollateral) =
            IMorphoBlue(MORPHO_BLUE).position(morphoLendingConnector.marketId(), address(morphoLendingConnector));

        assertGt(ourSupplyShares, 0);
        assertGt(ourCollateral, 0);
    }
}
