// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interfaces/IAaveV3Pool.sol";

contract AaveLiquidationTest is Test {
    IAaveV3Pool public AAVE_POOL = IAaveV3Pool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    IERC20 public WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public WETH_A_TOKEN = IERC20(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8);

    uint256 public constant PENALTY_PERCENT = 5;

    address public liquidator;

    function test_aaveLiquidation() public {
        vm.createSelectFork(vm.envString("RPC_MAINNET"), 22675172);

        address user = makeAddr("user");
        deal(address(WETH), user, 10 ** 18);

        vm.startPrank(user);
        WETH.approve(address(AAVE_POOL), 10 ** 18);
        AAVE_POOL.supply(address(WETH), 10 ** 18, user, 0);
        assertEq(WETH_A_TOKEN.balanceOf(user), 10 ** 18);
        AAVE_POOL.borrow(address(USDC), 2000 * 10 ** 6, 2, 0, user);

        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) = AAVE_POOL.getUserAccountData(user);

        assertGt(healthFactor, 1e18);

        vm.warp(block.timestamp + 1800 days);
        (totalCollateralBase, totalDebtBase, availableBorrowsBase, currentLiquidationThreshold, ltv, healthFactor) =
            AAVE_POOL.getUserAccountData(user);

        assertLt(healthFactor, 95 * 10 ** 16); // less than CLOSE_FACTOR_HF_THRESHOLD to be able to liquidate full debt

        uint256 totalAssetsBeforeLiquidation = totalCollateralBase - totalDebtBase;

        liquidator = makeAddr("liquidator");

        uint256 expectedLiquidatorWeth = totalDebtBase * (100 + PENALTY_PERCENT) / 100;
        uint256 expectedTotalAssetsChange = expectedLiquidatorWeth - totalDebtBase;

        vm.startPrank(liquidator);
        deal(address(USDC), liquidator, type(uint128).max);
        USDC.approve(address(AAVE_POOL), type(uint128).max);
        AAVE_POOL.liquidationCall(address(WETH), address(USDC), user, type(uint128).max, false);
        vm.stopPrank();

        (totalCollateralBase, totalDebtBase, availableBorrowsBase, currentLiquidationThreshold, ltv, healthFactor) =
            AAVE_POOL.getUserAccountData(user);

        uint256 totalAssetsAfterLiquidation = totalCollateralBase - totalDebtBase;

        assertEq(totalAssetsAfterLiquidation, totalAssetsBeforeLiquidation - expectedTotalAssetsChange - 1);

        vm.stopPrank();
    }
}
