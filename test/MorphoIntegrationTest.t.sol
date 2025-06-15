// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/connectors/lending_connectors/MorphoConnector.sol";
import "../src/connectors/lending_connectors/interfaces/IMorphoBlue.sol";
import "../src/elements/LTV.sol";
import "../src/dummy/DummyOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MorphoIntegrationTest is Test {
    address constant MORPHO_BLUE = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address constant MORPHO_ORACLE = 0x6F234Ff075B35312756A6B0a19DDb55Ff683E59d;
    address constant IRM = 0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC;

    MorphoConnector public morphoLendingConnector;
    DummyOracle public oracle;
    LTV public ltvVault;
    IERC20 public weth;
    IERC20 public wsteth;

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
        
        weth = IERC20(WETH);
        wsteth = IERC20(WSTETH);

        State.StateInitData memory stateInitData = State.StateInitData({
            collateralToken: WETH,
            borrowToken: WSTETH,
            feeCollector: address(this),
            maxSafeLTV: 800000000000000000,
            minProfitLTV: 750000000000000000,
            targetLTV: 750000000000000000,
            lendingConnector: address(morphoLendingConnector),
            oracleConnector: address(oracle),
            maxGrowthFee: 200000000000000000,
            maxTotalAssetsInUnderlying: type(uint256).max,
            slippageProvider: address(0),
            maxDeleverageFee: 50000000000000000,
            vaultBalanceAsLendingConnector: address(0)
        });

        ltvVault = new LTV();
        ltvVault.initialize(stateInitData, address(this), "", "");

        oracle.setAssetPrice(WETH, 3000 * 10**18);

        deal(address(wsteth), user, 100 ether);
        deal(address(weth), user, 100 ether);
    }

    function testDeposit() public {
        uint256 depositAmount = 1 ether;
        
        vm.startPrank(user);
        wsteth.approve(address(ltvVault), depositAmount);
        
        uint256 initialBalance = wsteth.balanceOf(user);
        uint256 shares = ltvVault.deposit(depositAmount, user);
        uint256 finalBalance = wsteth.balanceOf(user);
        
        assertEq(initialBalance - finalBalance, depositAmount);
        assertGt(shares, 0);
        assertEq(ltvVault.balanceOf(user), shares);
        
        uint256 realCollateralAssets = ltvVault.getRealCollateralAssets(true);
        assertGt(realCollateralAssets, 0);
        
        vm.stopPrank();
    }

    function testWithdraw() public {
        uint256 depositAmount = 2 ether;
        uint256 withdrawAmount = 1 ether;
        
        vm.startPrank(user);
        wsteth.approve(address(ltvVault), depositAmount);
        ltvVault.deposit(depositAmount, user);
        
        uint256 initialBalance = wsteth.balanceOf(user);
        uint256 sharesRedeemed = ltvVault.withdraw(withdrawAmount, user, user);
        uint256 finalBalance = wsteth.balanceOf(user);
        
        assertEq(finalBalance - initialBalance, withdrawAmount);
        assertGt(sharesRedeemed, 0);
        
        uint256 realCollateralAssets = ltvVault.getRealCollateralAssets(true);
        assertGt(realCollateralAssets, 0);
        
        vm.stopPrank();
    }

    function testMint() public {
        uint256 sharesToMint = 1 ether;
        
        vm.startPrank(user);
        wsteth.approve(address(ltvVault), type(uint256).max);
        
        uint256 initialBalance = wsteth.balanceOf(user);
        uint256 assetsUsed = ltvVault.mint(sharesToMint, user);
        uint256 finalBalance = wsteth.balanceOf(user);
        
        assertEq(initialBalance - finalBalance, assetsUsed);
        assertEq(ltvVault.balanceOf(user), sharesToMint);
        assertGt(assetsUsed, 0);
        
        uint256 realCollateralAssets = ltvVault.getRealCollateralAssets(true);
        assertGt(realCollateralAssets, 0);
        
        vm.stopPrank();
    }

    function testRedeem() public {
        uint256 depositAmount = 2 ether;
        uint256 sharesToRedeem = 1 ether;
        
        vm.startPrank(user);
        wsteth.approve(address(ltvVault), depositAmount);
        ltvVault.deposit(depositAmount, user);
        
        uint256 initialBalance = wsteth.balanceOf(user);
        uint256 assetsReceived = ltvVault.redeem(sharesToRedeem, user, user);
        uint256 finalBalance = wsteth.balanceOf(user);
        
        assertEq(finalBalance - initialBalance, assetsReceived);
        assertGt(assetsReceived, 0);
        
        uint256 realCollateralAssets = ltvVault.getRealCollateralAssets(true);
        assertGt(realCollateralAssets, 0);
        
        vm.stopPrank();
    }

    function testConnectorIntegration() public {
        vm.startPrank(user);
        
        wsteth.approve(address(ltvVault), 1 ether);
        ltvVault.deposit(1 ether, user);
        
        address actualLendingConnector = ltvVault.lendingConnector();
        
        assertEq(actualLendingConnector, address(morphoLendingConnector));
        
        uint256 realCollateralAssets = ltvVault.getRealCollateralAssets(true);
        uint256 realBorrowAssets = ltvVault.getRealBorrowAssets(true);
        
        assertGt(realCollateralAssets, 0);
        assertEq(realBorrowAssets, 0);
        
        vm.stopPrank();
    }

    function testDelegateCodeExecution() public {
        vm.startPrank(user);
        
        wsteth.approve(address(ltvVault), 5 ether);
        
        uint256 initialMorphoConnectorBalance = morphoLendingConnector.getRealCollateralAssets(true);
        
        ltvVault.deposit(5 ether, user);
        
        uint256 finalMorphoConnectorBalance = morphoLendingConnector.getRealCollateralAssets(true);
        uint256 ltvBalance = ltvVault.getRealCollateralAssets(true);
        
        assertGt(finalMorphoConnectorBalance, initialMorphoConnectorBalance);
        assertEq(ltvBalance, finalMorphoConnectorBalance);
        
        vm.stopPrank();
    }
}