// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import {ILendingConnector} from "../src/interfaces/ILendingConnector.sol";
import {IOracleConnector} from "../src/interfaces/IOracleConnector.sol";
import {IAaveOracle} from "../src/connectors/oracle_connectors/interfaces/IAaveOracle.sol";
import {AaveV3Connector} from "../src/connectors/lending_connectors/AaveV3Connector.sol";
import {AaveV3OracleConnector} from "../src/connectors/oracle_connectors/AaveV3OracleConnector.sol";

import {ModulesProvider, ModulesState} from "../src/elements/ModulesProvider.sol";
import {AuctionModule, IAuctionModule} from "../src/elements/AuctionModule.sol";
import {ERC20Module, IERC20Module} from "../src/elements/ERC20Module.sol";
import {CollateralVaultModule, ICollateralVaultModule} from "../src/elements/CollateralVaultModule.sol";
import {BorrowVaultModule, IBorrowVaultModule} from "../src/elements/BorrowVaultModule.sol";
import {LowLevelRebalanceModule, ILowLevelRebalanceModule} from "../src/elements/LowLevelRebalanceModule.sol";
import {AdministrationModule, IAdministrationModule} from "../src/elements/AdministrationModule.sol";

import {StateInitData} from "../src/structs/state/StateInitData.sol";
import {ConstantSlippageProvider} from "../src/connectors/slippage_providers/ConstantSlippageProvider.sol";
import {LTV} from "../src/elements/LTV.sol";

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
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        weth = IERC20(WETH);
        wsteth = IERC20(WSTETH);

        aaveLendingConnector = new AaveV3Connector(weth, wsteth);
        aaveV3OracleConnector = new AaveV3OracleConnector(WSTETH, WETH);
        slippageProvider = new ConstantSlippageProvider(10 ** 16, 10 ** 16, address(this));

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
            name: "AAVE LTV",
            symbol: "ALTV",
            decimals: 18,
            collateralToken: WSTETH,
            borrowToken: WETH,
            feeCollector: address(this),
            maxSafeLTV: 800000000000000000,
            minProfitLTV: 500000000000000000,
            targetLTV: 750000000000000000,
            lendingConnector: ILendingConnector(address(aaveLendingConnector)),
            oracleConnector: IOracleConnector(address(aaveV3OracleConnector)),
            maxGrowthFee: 200000000000000000,
            maxTotalAssetsInUnderlying: type(uint128).max,
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

        ltv = new LTV();
        ltv.initialize(stateInitData);

        deal(WETH, address(this), 100 ether);
        deal(WSTETH, address(this), 100 ether);
        weth.approve(address(ltv), 100 ether);
        wsteth.approve(address(ltv), 100 ether);

        ltv.executeLowLevelRebalanceShares(10 ether);

        deal(WETH, user, 100 ether);
        deal(WSTETH, user, 100 ether);
        vm.startPrank(user);
        weth.approve(address(ltv), 100 ether);
        wsteth.approve(address(ltv), 100 ether);
        vm.stopPrank();
    }

    function getRandomNumberInRange(uint256 x, uint256 min, uint256 max) public pure returns (uint256 random) {
        random = bound(x, min, max);
    }

    function test_AaveV3ConnectorSet() public view {
        assertEq(address(aaveLendingConnector.BORROW_ASSET()), WETH);
        assertEq(address(aaveLendingConnector.COLLATERAL_ASSET()), WSTETH);
    }

    function test_AaveV3ConnectorConfigs() public view {
        assertEq(address(ltv.getLendingConnector()), address(aaveLendingConnector));
        assertEq(address(ltv.oracleConnector()), address(aaveV3OracleConnector));
        assertEq(address(ltv.borrowToken()), WETH);
        assertEq(address(ltv.collateralToken()), WSTETH);
    }

    function test_AaveV3ConnectorDeposit() public {
        uint256 maxDeposit = ltv.maxDeposit(user);
        vm.prank(user);
        ltv.deposit(maxDeposit, user);
    }

    function test_AaveV3ConnectorMint() public {
        uint256 maxMint = ltv.maxMint(user);
        vm.prank(user);
        ltv.mint(maxMint, user);
    }

    function test_AaveV3ConnectorWithdraw() public {
        vm.startPrank(user);

        uint256 maxDeposit = ltv.maxDeposit(user);
        ltv.deposit(maxDeposit, user);
        uint256 maxWithdraw = ltv.maxWithdraw(user);
        ltv.withdraw(maxWithdraw, user, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorRedeem() public {
        vm.startPrank(user);

        uint256 maxDeposit = ltv.maxDeposit(user);
        ltv.deposit(maxDeposit, user);
        uint256 maxRedeem = ltv.maxRedeem(user);
        ltv.redeem(maxRedeem, user, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorDepositCollateral() public {
        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);
        vm.prank(user);
        ltv.depositCollateral(maxDepositCollateral, user);
    }

    function test_AaveV3ConnectorMintCollateral() public {
        uint256 maxMintCollateral = ltv.maxMintCollateral(user);
        vm.prank(user);
        ltv.mintCollateral(maxMintCollateral, user);
    }

    function test_AaveV3ConnectorWithdrawCollateral() public {
        vm.startPrank(user);

        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);
        ltv.depositCollateral(maxDepositCollateral, user);
        uint256 maxWithdrawCollateral = ltv.maxWithdrawCollateral(user);
        ltv.withdrawCollateral(maxWithdrawCollateral, user, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorRedeemCollateral() public {
        vm.startPrank(user);

        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);
        ltv.depositCollateral(maxDepositCollateral, user);
        uint256 maxRedeemCollateral = ltv.maxRedeemCollateral(user);
        ltv.redeemCollateral(maxRedeemCollateral, user, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorPartiallyDeposit(uint256 x) public {
        uint256 maxDeposit = ltv.maxDeposit(user);
        uint256 amountToDeposit = maxDeposit / getRandomNumberInRange(x, 2, 10);
        vm.prank(user);
        ltv.deposit(amountToDeposit, user);
    }

    function test_AaveV3ConnectorPartiallyMint(uint256 x) public {
        uint256 maxMint = ltv.maxMint(user);
        uint256 amountToMint = maxMint / getRandomNumberInRange(x, 2, 10);
        vm.prank(user);
        ltv.mint(amountToMint, user);
    }

    function test_AaveV3ConnectorPartiallyWithdraw(uint256 x) public {
        vm.startPrank(user);

        uint256 maxDeposit = ltv.maxDeposit(user);
        ltv.deposit(maxDeposit, user);
        uint256 maxWithdraw = ltv.maxWithdraw(user);
        uint256 amountToWithdraw = maxWithdraw / getRandomNumberInRange(x, 2, 10);
        ltv.withdraw(amountToWithdraw, user, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorPartiallyRedeem(uint256 x) public {
        vm.startPrank(user);

        uint256 maxDeposit = ltv.maxDeposit(user);
        ltv.deposit(maxDeposit, user);
        uint256 maxRedeem = ltv.maxRedeem(user);
        uint256 amountToRedeem = maxRedeem / getRandomNumberInRange(x, 2, 10);
        ltv.redeem(amountToRedeem, user, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorPartiallyDepositCollateral(uint256 x) public {
        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);
        uint256 amountToDeposit = maxDepositCollateral / getRandomNumberInRange(x, 2, 10);
        vm.prank(user);
        ltv.depositCollateral(amountToDeposit, user);
    }

    function test_AaveV3ConnectorPartiallyMintCollateral(uint256 x) public {
        uint256 maxMintCollateral = ltv.maxMintCollateral(user);
        uint256 amountToMint = maxMintCollateral / getRandomNumberInRange(x, 2, 10);
        vm.prank(user);
        ltv.mintCollateral(amountToMint, user);
    }

    function test_AaveV3ConnectorPartiallyWithdrawCollateral(uint256 x) public {
        vm.startPrank(user);

        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);
        ltv.depositCollateral(maxDepositCollateral, user);
        uint256 maxWithdrawCollateral = ltv.maxWithdrawCollateral(user);
        uint256 amountToWithdraw = maxWithdrawCollateral / getRandomNumberInRange(x, 2, 10);
        ltv.withdrawCollateral(amountToWithdraw, user, user);

        vm.stopPrank();
    }

    function test_AaveV3ConnectorPartiallyRedeemCollateral(uint256 x) public {
        vm.startPrank(user);

        uint256 maxDepositCollateral = ltv.maxDepositCollateral(user);
        ltv.depositCollateral(maxDepositCollateral, user);
        uint256 maxRedeemCollateral = ltv.maxRedeemCollateral(user);
        uint256 amountToRedeem = maxRedeemCollateral / getRandomNumberInRange(x, 2, 10);
        ltv.redeemCollateral(amountToRedeem, user, user);

        vm.stopPrank();
    }
}
