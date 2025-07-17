// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../src/interfaces/ILTV.sol";
import "forge-std/interfaces/IERC20.sol";
import "forge-std/Test.sol";
import "../../../src/Constants.sol";
import "../../../src/dummy/DummyOracleConnector.sol";

contract BasicInvariantWrapper is Test {
    ILTV internal ltv;
    address[10] public actors;
    address internal currentActor;

    uint256 internal totalAssets;
    uint256 internal totalSupply;

    int256 internal borrowUserBalanceBefore;
    int256 internal collateralUserBalanceBefore;
    int256 internal ltvUserBalanceBefore;
    int256 internal deltaBorrow;
    int256 internal deltaCollateral;
    int256 internal deltaLtv;
    uint256 internal lastSeenTokenPriceBefore;

    uint256 internal feeCollectorBorrowBalanceBefore;
    uint256 internal feeCollectorCollateralBalanceBefore;
    uint256 internal feeCollectorLtvBalanceBefore;

    int256 internal futureCollateralBefore;
    int256 internal rewardsBefore;
    uint256 internal startAuction;

    uint256 internal blockDelta;

    bool internal dataInitialized;

    bool public maxGrowthFeeReceived;
    bool public auctionRewardsReceived;

    constructor(ILTV _ltv, address[10] memory _actors) {
        vm.startPrank(address(1));
        ltv = _ltv;
        actors = _actors;
        vm.stopPrank();
    }

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = actors[bound(actorIndexSeed, 0, actors.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
        checkAndResetInvariants();
    }

    modifier makePostCheck() {
        _;
        checkAndResetInvariants();
    }

    function getInvariantsData() internal virtual {
        totalAssets = ltv.totalAssets();
        // Need to get real number of total supply since it can be affected by max growth fee
        totalSupply = ltv.convertToShares(totalAssets);
        borrowUserBalanceBefore = int256(IERC20(ltv.borrowToken()).balanceOf(currentActor));
        ltvUserBalanceBefore = int256(ltv.balanceOf(currentActor));
        collateralUserBalanceBefore = int256(IERC20(ltv.collateralToken()).balanceOf(currentActor));
        feeCollectorBorrowBalanceBefore = IERC20(ltv.borrowToken()).balanceOf(ltv.feeCollector());
        feeCollectorCollateralBalanceBefore = IERC20(ltv.collateralToken()).balanceOf(ltv.feeCollector());
        feeCollectorLtvBalanceBefore = ltv.balanceOf(ltv.feeCollector());
        futureCollateralBefore = ltv.futureCollateralAssets();
        int256 borrowPrice = int256(DummyOracleConnector(ltv.oracleConnector()).getPriceBorrowOracle());
        int256 collateralPrice = int256(DummyOracleConnector(ltv.oracleConnector()).getPriceCollateralOracle());
        rewardsBefore = (
            ltv.futureRewardBorrowAssets() * borrowPrice - ltv.futureRewardCollateralAssets() * collateralPrice
        ) / int256(Constants.ORACLE_DIVIDER);
        startAuction = ltv.startAuction();

        dataInitialized = true;
    }

    function checkAndResetInvariants() public virtual {
        if (!dataInitialized) {
            return;
        }

        assertGe(ltv.totalAssets() * totalSupply, totalAssets * ltv.totalSupply(), "Token price became smaller");
        assertEq(
            int256(IERC20(ltv.borrowToken()).balanceOf(currentActor)),
            borrowUserBalanceBefore + deltaBorrow,
            "Borrow balance changed"
        );
        assertEq(
            int256(IERC20(ltv.collateralToken()).balanceOf(currentActor)),
            collateralUserBalanceBefore - deltaCollateral,
            "Collateral balance changed"
        );
        assertEq(int256(ltv.balanceOf(currentActor)), ltvUserBalanceBefore + deltaLtv, "LTV balance changed");

        int256 borrowPrice = int256(DummyOracleConnector(ltv.oracleConnector()).getPriceBorrowOracle());
        int256 collateralPrice = int256(DummyOracleConnector(ltv.oracleConnector()).getPriceCollateralOracle());
        int256 rewardsAfter = (
            ltv.futureRewardBorrowAssets() * borrowPrice - ltv.futureRewardCollateralAssets() * collateralPrice
        ) / int256(Constants.ORACLE_DIVIDER);
        // need to multiply by 10 to ensure that we don't miss any rewards because of rounding
        if (
            startAuction + Constants.AMOUNT_OF_STEPS > block.number && checkAuctionExecuted()
                && rewardsBefore - rewardsAfter >= 10 * int256(Constants.AMOUNT_OF_STEPS)
        ) {
            assertTrue(
                feeCollectorBorrowBalanceBefore < IERC20(ltv.borrowToken()).balanceOf(ltv.feeCollector())
                    || feeCollectorCollateralBalanceBefore < IERC20(ltv.collateralToken()).balanceOf(ltv.feeCollector())
                    || feeCollectorLtvBalanceBefore < ltv.balanceOf(ltv.feeCollector()),
                "Auction rewards received"
            );
            auctionRewardsReceived = true;
        }

        if (
            lastSeenTokenPriceBefore != ltv.lastSeenTokenPrice()
                && (deltaBorrow * deltaCollateral != 0 || deltaBorrow * deltaLtv != 0 || deltaCollateral * deltaLtv != 0)
        ) {
            assertLt(feeCollectorLtvBalanceBefore, ltv.balanceOf(ltv.feeCollector()), "Max growth fee applied");
            maxGrowthFeeReceived = true;
        }

        blockDelta = 0;
        totalAssets = 0;
        totalSupply = 0;
        borrowUserBalanceBefore = 0;
        collateralUserBalanceBefore = 0;
        ltvUserBalanceBefore = 0;
        deltaBorrow = 0;
        deltaCollateral = 0;
        lastSeenTokenPriceBefore = 0;
        feeCollectorBorrowBalanceBefore = 0;
        feeCollectorCollateralBalanceBefore = 0;
        feeCollectorLtvBalanceBefore = 0;
        futureCollateralBefore = 0;
        dataInitialized = false;
    }

    function checkAuctionExecuted() internal view returns (bool) {
        return (
            futureCollateralBefore > 0 && futureCollateralBefore > ltv.futureCollateralAssets()
                || futureCollateralBefore < 0 && futureCollateralBefore < ltv.futureCollateralAssets()
        );
    }

    function moveBlock(uint256 blocks) internal {
        lastSeenTokenPriceBefore = ltv.lastSeenTokenPrice();
        blockDelta = bound(blocks, 1, Constants.AMOUNT_OF_STEPS);
        vm.roll(block.number + blockDelta);
    }
}
