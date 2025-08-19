// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BalancedTest} from "test/utils/BalancedTest.t.sol";
import {ILTV} from "src/interfaces/ILTV.sol";

contract LowLevelRebalanceTest is BalancedTest {
    function test_lowLevelNegativeAuctionShares(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -10000, -10000, 1000)
    {
        (int256 expectedDeltaRealCollateralAssets, int256 expectedDeltaRealBorrowAssets) =
            dummyLTV.previewLowLevelRebalanceShares(0);
        (int256 deltaRealCollateralAssets, int256 deltaRealBorrowAssets) = dummyLTV.executeLowLevelRebalanceShares(0);

        assertEq(deltaRealCollateralAssets, -4000);
        assertEq(deltaRealBorrowAssets, -7500);
        assertEq(expectedDeltaRealCollateralAssets, deltaRealCollateralAssets);
        assertEq(expectedDeltaRealBorrowAssets, deltaRealBorrowAssets);
    }

    function test_lowLevelNegativeAuctionCollateral(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -10000, -10000, 1000)
    {
        (int256 expectedDeltaRealBorrowAssets, int256 expectedDeltaShares) =
            dummyLTV.previewLowLevelRebalanceCollateral(-4000);
        (int256 deltaRealBorrowAssets, int256 deltaShares) = dummyLTV.executeLowLevelRebalanceCollateral(-4000);

        assertEq(deltaShares, 0);
        assertEq(deltaRealBorrowAssets, -7500);
        assertEq(expectedDeltaShares, deltaShares);
        assertEq(expectedDeltaRealBorrowAssets, deltaRealBorrowAssets);
    }

    function test_lowLevelNegativeAuctionCollateralHint(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -10000, -10000, 1000)
    {
        (int256 expectedDeltaRealBorrowAssets, int256 expectedDeltaShares) =
            ILTV(address(dummyLTV)).previewLowLevelRebalanceCollateralHint(-4000, true);
        (int256 deltaRealBorrowAssets, int256 deltaShares) =
            ILTV(address(dummyLTV)).executeLowLevelRebalanceCollateralHint(-4000, true);

        assertEq(deltaShares, 0);
        assertEq(deltaRealBorrowAssets, -7500);
        assertEq(expectedDeltaShares, deltaShares);
        assertEq(expectedDeltaRealBorrowAssets, deltaRealBorrowAssets);
    }

    function test_lowLevelNegativeAuctionBorrow(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -10000, -10000, 1000)
    {
        (int256 expectedDeltaRealCollateralAssets, int256 expectedDeltaShares) =
            dummyLTV.previewLowLevelRebalanceBorrow(-7500);
        (int256 deltaRealCollateralAssets, int256 deltaShares) = dummyLTV.executeLowLevelRebalanceBorrow(-7500);

        assertEq(deltaShares, 0);
        assertEq(deltaRealCollateralAssets, -4000);
        assertEq(expectedDeltaShares, deltaShares);
        assertEq(expectedDeltaRealCollateralAssets, deltaRealCollateralAssets);
    }

    function test_lowLevelNegativeAuctionBorrowHint(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, -10000, -10000, 1000)
    {
        (int256 expectedDeltaRealCollateralAssets, int256 expectedDeltaShares) =
            ILTV(address(dummyLTV)).previewLowLevelRebalanceBorrowHint(-7500, true);
        (int256 deltaRealCollateralAssets, int256 deltaShares) =
            dummyLTV.executeLowLevelRebalanceBorrowHint(-7500, true);

        assertEq(deltaShares, 0);
        assertEq(deltaRealCollateralAssets, -4000);
        assertEq(expectedDeltaShares, deltaShares);
        assertEq(expectedDeltaRealCollateralAssets, deltaRealCollateralAssets);
    }

    function test_lowLevelPositiveAuctionShares(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, 10000, 10000, -1000)
    {
        (int256 expectedDeltaRealCollateralAssets, int256 expectedDeltaRealBorrowAssets) =
            dummyLTV.previewLowLevelRebalanceShares(1000);
        (int256 deltaRealCollateralAssets, int256 deltaRealBorrowAssets) = dummyLTV.executeLowLevelRebalanceShares(1000);

        assertEq(deltaRealCollateralAssets, 7500);
        assertEq(deltaRealBorrowAssets, 14500);
        assertEq(expectedDeltaRealCollateralAssets, deltaRealCollateralAssets);
        assertEq(expectedDeltaRealBorrowAssets, deltaRealBorrowAssets);
    }

    function test_lowLevelPositiveAuctionBorrow(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, 10000, 10000, -1000)
    {
        (int256 expectedDeltaRealCollateralAssets, int256 expectedDeltaShares) =
            dummyLTV.previewLowLevelRebalanceBorrow(14500);
        (int256 deltaRealCollateralAssets, int256 deltaShares) = dummyLTV.executeLowLevelRebalanceBorrow(14500);

        assertEq(deltaRealCollateralAssets, 7500);
        assertEq(deltaShares, 1000);
        assertEq(expectedDeltaRealCollateralAssets, deltaRealCollateralAssets);
        assertEq(expectedDeltaShares, deltaShares);
    }

    function test_lowLevelPositiveAuctionBorrowHint(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, 10000, 10000, -1000)
    {
        (int256 expectedDeltaRealCollateralAssets, int256 expectedDeltaShares) =
            ILTV(address(dummyLTV)).previewLowLevelRebalanceBorrowHint(14500, true);
        (int256 deltaRealCollateralAssets, int256 deltaShares) =
            dummyLTV.executeLowLevelRebalanceBorrowHint(14500, true);

        assertEq(deltaRealCollateralAssets, 7500);
        assertEq(deltaShares, 1000);
        assertEq(expectedDeltaRealCollateralAssets, deltaRealCollateralAssets);
        assertEq(expectedDeltaShares, deltaShares);
    }

    function test_lowLevelPositiveAuctionCollateral(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, 10000, 10000, -1000)
    {
        (int256 expectedDeltaRealBorrowAssets, int256 expectedDeltaShares) =
            dummyLTV.previewLowLevelRebalanceCollateral(7500);
        (int256 deltaRealBorrowAssets, int256 deltaShares) = dummyLTV.executeLowLevelRebalanceCollateral(7500);

        assertEq(deltaRealBorrowAssets, 14500);
        assertEq(deltaShares, 1000);
        assertEq(expectedDeltaRealBorrowAssets, deltaRealBorrowAssets);
        assertEq(expectedDeltaShares, deltaShares);
    }

    function test_lowLevelPositiveAuctionCollateralHint(address owner, address user)
        public
        initializeBalancedTest(owner, user, 100000, 10000, 10000, -1000)
    {
        (int256 expectedDeltaRealBorrowAssets, int256 expectedDeltaShares) =
            ILTV(address(dummyLTV)).previewLowLevelRebalanceCollateralHint(7500, true);
        (int256 deltaRealBorrowAssets, int256 deltaShares) = dummyLTV.executeLowLevelRebalanceCollateralHint(7500, true);

        assertEq(deltaRealBorrowAssets, 14500);
        assertEq(deltaShares, 1000);
        assertEq(expectedDeltaRealBorrowAssets, deltaRealBorrowAssets);
        assertEq(expectedDeltaShares, deltaShares);
    }

    function test_maxLowLevelRebalanceCollateral(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        vm.startPrank(ILTV(address(dummyLTV)).governor());
        dummyLTV.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLTV.maxLowLevelRebalanceCollateral(), 2 * 10 ** 6);
    }

    function test_maxLowLevelRebalanceBorrow(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        vm.startPrank(ILTV(address(dummyLTV)).governor());
        dummyLTV.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLTV.maxLowLevelRebalanceBorrow(), 3 * 10 ** 6);
    }

    function test_maxLowLevelRebalanceShares(address owner, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.stopPrank();
        vm.startPrank(ILTV(address(dummyLTV)).governor());
        dummyLTV.setMaxTotalAssetsInUnderlying(10 ** 18 * 100 + 10 ** 8);
        assertEq(dummyLTV.maxLowLevelRebalanceShares(), 10 ** 6);
    }
}
