// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {MorphoConnector} from "../src/connectors/lending_connectors/MorphoConnector.sol";
import {IMorphoBlue} from "../src/connectors/lending_connectors/interfaces/IMorphoBlue.sol";

contract MorphoBlueBordersTest is Test {
    address constant MORPHO_BLUE = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address constant MORPHO_ORACLE = 0x6F234Ff075B35312756A6B0a19DDb55Ff683E59d;
    address constant IRM = 0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC;

    MorphoConnector public morphoBlueConnector;
    IERC20 public weth;
    IERC20 public wsteth;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        IMorphoBlue.MarketParams memory marketParams = IMorphoBlue.MarketParams({
            loanToken: WSTETH,
            collateralToken: WETH,
            oracle: MORPHO_ORACLE,
            irm: IRM,
            lltv: 945000000000000000
        });

        morphoBlueConnector = new MorphoConnector(marketParams);
        weth = IERC20(WETH);
        wsteth = IERC20(WSTETH);

        _setupInitialState();
    }

    function _setupInitialState() internal {
        uint256 initialSupplyAmount = 1000 ether;
        uint256 initialCollateralAmount = 100 ether;
        uint256 initialBorrowAmount = 50 ether;

        deal(address(wsteth), address(morphoBlueConnector), initialSupplyAmount);
        deal(address(weth), address(morphoBlueConnector), initialCollateralAmount);

        morphoBlueConnector.supply(initialSupplyAmount);
        morphoBlueConnector.supplyCollateral(initialCollateralAmount);
        morphoBlueConnector.borrow(initialBorrowAmount);
    }

    function test_getRealBorrowAssets_ExactDebt() public {
        (, uint256 borrowShares,) =
            IMorphoBlue(MORPHO_BLUE).position(morphoBlueConnector.marketId(), address(morphoBlueConnector));

        if (borrowShares == 0) {
            uint256 repaymentAmount = morphoBlueConnector.getRealBorrowAssets(false);
            assertEq(repaymentAmount, 0);
            return;
        }

        (,, uint256 totalBorrowAssets, uint256 totalBorrowShares,,) =
            IMorphoBlue(MORPHO_BLUE).market(morphoBlueConnector.marketId());

        uint256 expectedDebtAmount = (borrowShares * totalBorrowAssets) / totalBorrowShares;
        uint256 borrowAssetsForRepayment = morphoBlueConnector.getRealBorrowAssets(false);

        assertGe(borrowAssetsForRepayment, expectedDebtAmount);
        assertLe(borrowAssetsForRepayment, expectedDebtAmount + 1);

        uint256 balanceBefore = wsteth.balanceOf(address(morphoBlueConnector));
        deal(address(wsteth), address(morphoBlueConnector), balanceBefore + borrowAssetsForRepayment);

        morphoBlueConnector.repay(borrowAssetsForRepayment);

        (, uint256 newBorrowShares,) =
            IMorphoBlue(MORPHO_BLUE).position(morphoBlueConnector.marketId(), address(morphoBlueConnector));

        assertEq(newBorrowShares, 0);
    }

    function test_getRealCollateralAssets_ExactWithdrawable() public {
        uint256 totalDebt = morphoBlueConnector.getRealBorrowAssets(false);
        if (totalDebt > 0) {
            deal(
                address(wsteth),
                address(morphoBlueConnector),
                wsteth.balanceOf(address(morphoBlueConnector)) + totalDebt
            );
            morphoBlueConnector.repay(totalDebt);
        }

        (uint256 supplyShares,,) =
            IMorphoBlue(MORPHO_BLUE).position(morphoBlueConnector.marketId(), address(morphoBlueConnector));

        if (supplyShares == 0) {
            uint256 withdrawalAmount = morphoBlueConnector.getRealCollateralAssets(true);
            assertEq(withdrawalAmount, 0);
            return;
        }

        (uint256 totalSupplyAssets, uint256 totalSupplyShares,,,,) =
            IMorphoBlue(MORPHO_BLUE).market(morphoBlueConnector.marketId());

        uint256 expectedSupplyAmount = (supplyShares * totalSupplyAssets) / totalSupplyShares;
        uint256 collateralAssetsForWithdrawal = morphoBlueConnector.getRealCollateralAssets(true);

        assertLe(collateralAssetsForWithdrawal, expectedSupplyAmount);
        assertGe(collateralAssetsForWithdrawal, expectedSupplyAmount - 1);

        uint256 balanceBefore = wsteth.balanceOf(address(morphoBlueConnector));
        morphoBlueConnector.withdraw(collateralAssetsForWithdrawal);
        uint256 balanceAfter = wsteth.balanceOf(address(morphoBlueConnector));

        assertEq(balanceAfter - balanceBefore, collateralAssetsForWithdrawal);
    }
}
