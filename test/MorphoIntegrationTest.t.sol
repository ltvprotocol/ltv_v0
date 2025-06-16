// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {MorphoConnector} from "../src/connectors/lending_connectors/MorphoConnector.sol";
import {IMorphoBlue} from "../src/connectors/lending_connectors/interfaces/IMorphoBlue.sol";
import {LTV} from "../src/elements/LTV.sol";
import {DummyOracle} from "../src/dummy/DummyOracle.sol";
import {DummyOracleConnector} from "../src/dummy/DummyOracleConnector.sol";
import "forge-std/interfaces/IERC20.sol";
import {StateInitData} from "../src/structs/state/StateInitData.sol";
import {ConstantSlippageProvider} from "../src/connectors/slippage_providers/ConstantSlippageProvider.sol";
import {VaultBalanceAsLendingConnector} from "../src/connectors/lending_connectors/VaultBalanceAsLendingConnector.sol";
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
    DummyOracle public oracle;
    DummyOracleConnector public oracleConnector;
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
        oracle = new DummyOracle(address(this));
        slippageProvider = new ConstantSlippageProvider(10**16, 10**16, address(this));
        
        weth = IERC20(WETH);
        wsteth = IERC20(WSTETH);
        
        oracleConnector = new DummyOracleConnector(weth, wsteth, oracle);

        {
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
                name: "123",
                symbol: "123",
                decimals: 18,
                collateralToken: WETH,
                borrowToken: WSTETH,
                feeCollector: address(this),
                maxSafeLTV: 800000000000000000,
                minProfitLTV: 750000000000000000,
                targetLTV: 750000000000000000,
                lendingConnector: ILendingConnector(address(morphoLendingConnector)),
                oracleConnector: IOracleConnector(address(oracleConnector)),
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
        }

        oracle.setAssetPrice(WSTETH, 3500 * 10**18);
        oracle.setAssetPrice(WETH, 3000 * 10**18);

        deal(address(wsteth), user, 100 ether);
        deal(address(weth), user, 100 ether);
    }

    function testMorphoConnectorIntegration() public {
        deal(address(wsteth), address(morphoLendingConnector), 5 ether);
        
        vm.startPrank(address(morphoLendingConnector));
        wsteth.approve(address(MORPHO_BLUE), 5 ether);
        vm.stopPrank();
        
        uint256 initialCollateral = morphoLendingConnector.getRealCollateralAssets(true);
        uint256 initialBorrow = morphoLendingConnector.getRealBorrowAssets(true);
        
        vm.prank(address(ltvVault));
        morphoLendingConnector.supply(1 ether);
        
        uint256 finalCollateral = morphoLendingConnector.getRealCollateralAssets(true);
        uint256 finalBorrow = morphoLendingConnector.getRealBorrowAssets(true);
        
        assertGt(finalCollateral, initialCollateral);
        assertEq(finalBorrow, 0);
    }

    function testVaultConfiguration() public {
        ILendingConnector actualLendingConnector = ILendingConnector(ltvVault.getLendingConnector());
        assertEq(address(actualLendingConnector), address(morphoLendingConnector));
        
        uint256 realCollateralAssets = actualLendingConnector.getRealCollateralAssets(true);
        uint256 realBorrowAssets = actualLendingConnector.getRealBorrowAssets(true);
        
        assertEq(realCollateralAssets, 0);
        assertEq(realBorrowAssets, 0);
    }

    function testOraclePrices() public {
        uint256 wethPrice = oracle.getAssetPrice(WETH);
        uint256 wstethPrice = oracle.getAssetPrice(WSTETH);
        
        assertEq(wethPrice, 3000 * 10**18);
        assertEq(wstethPrice, 3500 * 10**18);
    }

    function testVaultInitialState() public {
        uint256 totalAssets = ltvVault.totalAssets();
        uint256 totalSupply = ltvVault.totalSupply();
        uint256 realCollateral = ltvVault.getRealCollateralAssets(true);
        uint256 realBorrow = ltvVault.getRealBorrowAssets(true);
        
        assertEq(totalAssets, 10000);
        assertEq(totalSupply, 10000);
        assertEq(realCollateral, 0);
        assertEq(realBorrow, 0);
    }

    function testMaxDepositEmpty() public {
        uint256 maxDeposit = ltvVault.maxDeposit(user);
        assertEq(maxDeposit, 0);
    }

    function testDepositFails() public {
        vm.startPrank(user);
        wsteth.approve(address(ltvVault), 0.1 ether);
        
        vm.expectRevert();
        ltvVault.deposit(0.1 ether, user);
        
        vm.stopPrank();
    }
}