// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, BaseTestInit} from "../../utils/BaseTest.t.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract NearZeroAuctionFinalRoundingTest is BaseTest {
    using SafeERC20 for IERC20;

    address internal user;

    function setUp() public {
        BaseTestInit memory init = BaseTestInit({
            owner: address(1),
            guardian: address(2),
            governor: address(3),
            emergencyDeleverager: address(4),
            feeCollector: address(5),
            futureBorrow: -3000000,
            futureCollateral: -1421099,
            auctionReward: 30000,
            startAuction: 0,
            collateralSlippage: 10 ** 16,
            borrowSlippage: 10 ** 16,
            maxTotalAssetsInUnderlying: type(uint128).max,
            collateralAssets: 1894736842,
            borrowAssets: 3000000000,
            maxSafeLtvDividend: 9,
            maxSafeLtvDivider: 10,
            minProfitLtvDividend: 5,
            minProfitLtvDivider: 10,
            targetLtvDividend: 75,
            targetLtvDivider: 100,
            maxGrowthFeeDividend: 0,
            maxGrowthFeeDivider: 5,
            collateralPrice: 2111111111111111111,
            borrowPrice: 10 ** 18,
            maxDeleverageFeeDividend: 0,
            maxDeleverageFeeDivider: 50,
            zeroAddressTokens: 10707579638052243058,
            softLiquidationFeeDividend: 1,
            softLiquidationFeeDivider: 100,
            softLiquidationLtvDividend: 1,
            softLiquidationLtvDivider: 1
        });

        initializeTest(init);

        user = address(6);
        vm.prank(address(0));
        IERC20(address(ltv)).safeTransfer(user, 3352157413899479141);
    }

    function test_nearZeroAuctionFinalRounding() public {
        uint256 initialTotalAssets = ltv.totalAssets();
        uint256 initialTotalSupply = ltv.convertToShares(initialTotalAssets);
        vm.startPrank(user);
        ltv.deposit(0, user);

        // TODO: Investigate why the future assets are set to 1 instead of 0
        assertEq(ltv.futureCollateralAssets(), 1);
        assertEq(ltv.futureBorrowAssets(), 1);
        assertGe(
            ltv.totalAssets() * initialTotalSupply, initialTotalAssets * ltv.totalSupply(), "Token price became smaller"
        );
    }
}
