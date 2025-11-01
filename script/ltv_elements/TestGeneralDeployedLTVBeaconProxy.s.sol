// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILTV, IAdministrationErrors} from "../../src/interfaces/ILTV.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Script} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {ISafe4626} from "./interface/ISafe4626.s.sol";
import {ISafe4626Collateral} from "./interface/ISafe4626Collateral.s.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {WhitelistRegistry} from "../../src/elements/WhitelistRegistry.sol";
import {console} from "forge-std/console.sol";

struct ExpectedResults {
    uint256 sharesAfter1LowLevelRebalanceDeposit;
    uint256 collateralAfter1LowLevelRebalanceDeposit;
    uint256 borrowAfter1LowLevelRebalanceDeposit;
    uint256 sharesAfter1LowLevelRebalanceWithdraw;
    uint256 collateralAfter1LowLevelRebalanceWithdraw;
    uint256 borrowAfter1LowLevelRebalanceWithdraw;
    uint256 assetsAfter1SafeDeposit;
    uint256 sharesAfter1SafeDeposit;
    uint256 assetsAfter1SafeMint;
    uint256 sharesAfter1SafeMint;
    uint256 borrowAfter1DepositAuctionExecution;
    uint256 collateralAfter1DepositAuctionExecution;
    uint256 assetsAfter1SafeDepositCollateral;
    uint256 sharesAfter1SafeDepositCollateral;
    uint256 assetsAfter1SafeMintCollateral;
    uint256 sharesAfter1SafeMintCollateral;
    uint256 assetsAfter1SafeWithdrawCollateral;
    uint256 sharesAfter1SafeWithdrawCollateral;
    uint256 assetsAfter1SafeRedeemCollateral;
    uint256 sharesAfter1SafeRedeemCollateral;
    uint256 assetsAfter1SafeRedeem;
    uint256 sharesAfter1SafeRedeem;
    uint256 assetsAfter1SafeWithdraw;
    uint256 sharesAfter1SafeWithdraw;
    uint256 sharesAfter2SafeDeposit;
    uint256 assetsAfter2SafeDeposit;
    uint256 collateralAfter1WithdrawAuctionExecution;
    uint256 borrowAfter1WithdrawAuctionExecution;
}

// forge-lint: disable-start(unsafe-typecast)
contract TestGeneralDeployedLTVBeaconProxy is Script, StdCheats, StdAssertions {
    ILTV public ltv;
    ISafe4626 public safe4626;
    ISafe4626Collateral public safe4626Collateral;
    address public user;
    IERC20 public collateralToken;
    IERC20 public borrowToken;
    WhitelistRegistry public whitelistRegistry;

    function run() public virtual {
        _beforeTest();
        _performTest();
    }

    function _beforeTest() internal virtual {
        vm.createSelectFork("http://127.0.0.1:8545");

        user = msg.sender;
        ltv = ILTV(vm.envAddress("LTV_BEACON_PROXY"));
        collateralToken = IERC20(ltv.assetCollateral());
        borrowToken = IERC20(ltv.asset());
        safe4626 = ISafe4626(vm.envAddress("SAFE_4626"));
        safe4626Collateral = ISafe4626Collateral(vm.envAddress("SAFE_4626_COLLATERAL"));
        whitelistRegistry = WhitelistRegistry(vm.envAddress("WHITELIST_REGISTRY"));

        vm.startPrank(user);
    }

    function _expectedResults() internal pure virtual returns (ExpectedResults memory) {
        return ExpectedResults({
            sharesAfter1LowLevelRebalanceDeposit: type(uint256).max,
            collateralAfter1LowLevelRebalanceDeposit: type(uint256).max,
            borrowAfter1LowLevelRebalanceDeposit: type(uint256).max,
            sharesAfter1LowLevelRebalanceWithdraw: type(uint256).max,
            collateralAfter1LowLevelRebalanceWithdraw: type(uint256).max,
            borrowAfter1LowLevelRebalanceWithdraw: type(uint256).max,
            assetsAfter1SafeDeposit: type(uint256).max,
            sharesAfter1SafeDeposit: type(uint256).max,
            assetsAfter1SafeMint: type(uint256).max,
            sharesAfter1SafeMint: type(uint256).max,
            assetsAfter1SafeDepositCollateral: type(uint256).max,
            sharesAfter1SafeDepositCollateral: type(uint256).max,
            assetsAfter1SafeMintCollateral: type(uint256).max,
            sharesAfter1SafeMintCollateral: type(uint256).max,
            assetsAfter1SafeWithdrawCollateral: type(uint256).max,
            sharesAfter1SafeWithdrawCollateral: type(uint256).max,
            assetsAfter1SafeRedeemCollateral: type(uint256).max,
            sharesAfter1SafeRedeemCollateral: type(uint256).max,
            borrowAfter1DepositAuctionExecution: type(uint256).max,
            collateralAfter1DepositAuctionExecution: type(uint256).max,
            assetsAfter1SafeRedeem: type(uint256).max,
            sharesAfter1SafeRedeem: type(uint256).max,
            assetsAfter1SafeWithdraw: type(uint256).max,
            sharesAfter1SafeWithdraw: type(uint256).max,
            sharesAfter2SafeDeposit: type(uint256).max,
            assetsAfter2SafeDeposit: type(uint256).max,
            collateralAfter1WithdrawAuctionExecution: type(uint256).max,
            borrowAfter1WithdrawAuctionExecution: type(uint256).max
        });
    }

    function _performTest() internal {
        ExpectedResults memory expectedResults = _expectedResults();
        assertEq(ltv.isProtocolPaused(), true, "Protocol should be paused by default");

        vm.expectRevert(IAdministrationErrors.ProtocolIsPaused.selector);
        ltv.executeLowLevelRebalanceShares(int256(0));

        ltv.setIsProtocolPaused(false);
        assertEq(ltv.isProtocolPaused(), false, "Protocol should be unpaused");

        assertEq(ltv.isWhitelistActivated(), true, "Whitelist should be activated by default");

        _performMintWithLowLevelRebalance(
            expectedResults.collateralAfter1LowLevelRebalanceDeposit,
            expectedResults.borrowAfter1LowLevelRebalanceDeposit,
            expectedResults.sharesAfter1LowLevelRebalanceDeposit,
            abi.encodeWithSelector(IAdministrationErrors.ReceiverNotWhitelisted.selector, user)
        );

        whitelistRegistry.addAddressToWhitelist(user);

        _performMintWithLowLevelRebalance(
            expectedResults.collateralAfter1LowLevelRebalanceDeposit,
            expectedResults.borrowAfter1LowLevelRebalanceDeposit,
            expectedResults.sharesAfter1LowLevelRebalanceDeposit,
            ""
        );

        whitelistRegistry.removeAddressFromWhitelist(user);

        _performRedeemWithLowLevelRebalance(
            expectedResults.collateralAfter1LowLevelRebalanceWithdraw,
            expectedResults.borrowAfter1LowLevelRebalanceWithdraw,
            expectedResults.sharesAfter1LowLevelRebalanceWithdraw,
            abi.encodeWithSelector(IAdministrationErrors.ReceiverNotWhitelisted.selector, user)
        );


        whitelistRegistry.addAddressToWhitelist(user);

        _performRedeemWithLowLevelRebalance(
            expectedResults.collateralAfter1LowLevelRebalanceWithdraw,
            expectedResults.borrowAfter1LowLevelRebalanceWithdraw,
            expectedResults.sharesAfter1LowLevelRebalanceWithdraw,
            ""
        );

        _makeSafeDeposit(expectedResults.assetsAfter1SafeDeposit, expectedResults.sharesAfter1SafeDeposit);
        vm.roll(ltv.startAuction() + ltv.auctionDuration() / 2);
        _makeSafeMint(expectedResults.assetsAfter1SafeMint, expectedResults.sharesAfter1SafeMint);
        vm.roll(ltv.startAuction() + ltv.auctionDuration() / 2);
        _makeSafeDepositCollateral(
            expectedResults.assetsAfter1SafeDepositCollateral, expectedResults.sharesAfter1SafeDepositCollateral
        );
        vm.roll(ltv.startAuction() + ltv.auctionDuration() / 2);
        _makeSafeMintCollateral(
            expectedResults.assetsAfter1SafeMintCollateral, expectedResults.sharesAfter1SafeMintCollateral
        );
        vm.roll(ltv.startAuction() + ltv.auctionDuration() / 2);

        _performFullDepositAuctionExecution(
            expectedResults.collateralAfter1DepositAuctionExecution, expectedResults.borrowAfter1DepositAuctionExecution
        );
        _makeSafeWithdrawCollateral(
            expectedResults.assetsAfter1SafeWithdrawCollateral, expectedResults.sharesAfter1SafeWithdrawCollateral
        );
        vm.roll(ltv.startAuction() + ltv.auctionDuration() / 2);
        _makeSafeRedeemCollateral(
            expectedResults.assetsAfter1SafeRedeemCollateral, expectedResults.sharesAfter1SafeRedeemCollateral
        );
        vm.roll(ltv.startAuction() + ltv.auctionDuration() / 2);
        _makeSafeWithdraw(expectedResults.assetsAfter1SafeWithdraw, expectedResults.sharesAfter1SafeWithdraw);
        vm.roll(ltv.startAuction() + ltv.auctionDuration() / 2);
        _makeSafeRedeem(expectedResults.assetsAfter1SafeRedeem, expectedResults.sharesAfter1SafeRedeem);
        vm.roll(ltv.startAuction() + ltv.auctionDuration() / 2);
        _makeSafeDeposit(expectedResults.assetsAfter2SafeDeposit, expectedResults.sharesAfter2SafeDeposit);
        _performFullWithdrawAuctionExecution(
            expectedResults.collateralAfter1WithdrawAuctionExecution,
            expectedResults.borrowAfter1WithdrawAuctionExecution
        );

        assertGe(ltv.convertToAssets(10**18), 10**18, "Convert to assets should be greater than 1");
    }

    function _makeSafeDeposit(uint256 expectedAssets, uint256 expectedShares) internal virtual {
        if (expectedAssets == type(uint256).max) {
            expectedAssets = ltv.maxDeposit(user) / 10;
            console.log("assetsAfterSafeDeposit", expectedAssets);
        }

        uint256 initialBalance = ltv.balanceOf(user);

        uint256 shares = ltv.previewDeposit(expectedAssets);
        _receiveBorrowTokens(expectedAssets);
        borrowToken.approve(address(safe4626), expectedAssets);
        uint256 sharesOut = safe4626.safeDeposit(address(ltv), expectedAssets, user, shares);
        assertEq(sharesOut, shares, "Safe deposit returned incorrect number of shares compared to preview");

        assertEq(ltv.balanceOf(user), initialBalance + shares, "Safe deposit should increase the balance of the ltv");
        if (expectedShares != type(uint256).max) {
            assertEq(sharesOut, expectedShares, "Safe deposit returned incorrect number of shares compared to expected");
        } else {
            console.log("sharesAfterSafeDeposit", sharesOut);
        }
    }

    function _makeSafeMint(uint256 assetsExpected, uint256 sharesExpected) internal virtual {
        if (sharesExpected == type(uint256).max) {
            sharesExpected = ltv.maxMint(user) / 10;
            console.log("sharesAfterSafeMint", sharesExpected);
        }
        uint256 initialBalance = ltv.balanceOf(user);

        uint256 assets = ltv.previewMint(sharesExpected);
        _receiveBorrowTokens(assets);
        borrowToken.approve(address(safe4626), assets);
        uint256 assetsIn = safe4626.safeMint(address(ltv), sharesExpected, user, assets);
        assertEq(assetsIn, assets, "Safe mint returned incorrect number of assets compared to preview");

        assertEq(
            ltv.balanceOf(user), initialBalance + sharesExpected, "Safe mint should increase the balance of the ltv"
        );
        if (assetsExpected != type(uint256).max) {
            assertEq(assetsIn, assetsExpected, "Safe mint returned incorrect number of assets compared to expected");
        } else {
            console.log("assetsAfterSafeMint", assetsIn);
        }
    }

    function _makeSafeWithdraw(uint256 expectedAssets, uint256 expectedShares) internal virtual {
        if (expectedAssets == type(uint256).max) {
            expectedAssets = ltv.maxWithdraw(user) / 10;
            console.log("assetsAfterSafeWithdraw", expectedAssets);
        }
        uint256 initialBalance = ltv.balanceOf(user);

        uint256 shares = ltv.previewWithdraw(expectedAssets);
        ltv.approve(address(safe4626), shares);
        uint256 sharesOut = safe4626.safeWithdraw(address(ltv), expectedAssets, user, shares);

        assertEq(sharesOut, shares, "Safe withdraw returned incorrect number of shares compared to preview");

        assertEq(ltv.balanceOf(user), initialBalance - shares, "Safe withdraw should decrease the balance of the ltv");
        if (expectedShares != type(uint256).max) {
            assertEq(
                sharesOut, expectedShares, "Safe withdraw returned incorrect number of shares compared to expected"
            );
        } else {
            console.log("sharesAfterSafeWithdraw", sharesOut);
        }
    }

    function _makeSafeRedeem(uint256 expectedAssets, uint256 expectedShares) internal virtual {
        if (expectedShares == type(uint256).max) {
            expectedShares = ltv.maxRedeem(user) / 10;
            console.log("sharesAfterSafeRedeem", expectedShares);
        }
        uint256 initialBalance = ltv.balanceOf(user);
        uint256 assets = ltv.previewRedeem(expectedShares);
        ltv.approve(address(safe4626), expectedShares);
        uint256 assetsOut = safe4626.safeRedeem(address(ltv), expectedShares, user, assets);
        assertEq(assetsOut, assets, "Safe redeem returned incorrect number of assets compared to preview");
        assertEq(
            ltv.balanceOf(user), initialBalance - expectedShares, "Safe redeem should decrease the balance of the ltv"
        );
        if (expectedAssets != type(uint256).max) {
            assertEq(assetsOut, expectedAssets, "Safe redeem returned incorrect number of assets compared to expected");
        } else {
            console.log("assetsAfterSafeRedeem", assetsOut);
        }
    }

    function _makeSafeDepositCollateral(uint256 expectedAssets, uint256 expectedShares) internal virtual {
        if (expectedAssets == type(uint256).max) {
            expectedAssets = ltv.maxDepositCollateral(user) / 10;
            console.log("assetsAfterSafeDepositCollateral", expectedAssets);
        }

        uint256 shares = ltv.previewDepositCollateral(expectedAssets);
        _receiveCollateralTokens(expectedAssets);
        collateralToken.approve(address(safe4626Collateral), expectedAssets);
        uint256 sharesOut = safe4626Collateral.safeDepositCollateral(address(ltv), expectedAssets, user, shares);
        assertEq(sharesOut, shares, "Safe deposit collateral returned incorrect number of shares compared to preview");

        if (expectedShares != type(uint256).max) {
            assertEq(
                sharesOut,
                expectedShares,
                "Safe deposit collateral returned incorrect number of shares compared to expected"
            );
        } else {
            console.log("sharesAfterSafeDepositCollateral", sharesOut);
        }
    }

    function _makeSafeMintCollateral(uint256 assetsExpected, uint256 sharesExpected) internal virtual {
        if (sharesExpected == type(uint256).max) {
            sharesExpected = ltv.maxMintCollateral(user) / 10;
            console.log("sharesAfterSafeMintCollateral", sharesExpected);
        }

        uint256 assets = ltv.previewMintCollateral(sharesExpected);
        _receiveCollateralTokens(assets);
        collateralToken.approve(address(safe4626Collateral), assets);
        uint256 assetsIn = safe4626Collateral.safeMintCollateral(address(ltv), sharesExpected, user, assets);
        assertEq(assetsIn, assets, "Safe mint collateral returned incorrect number of assets compared to preview");

        if (assetsExpected != type(uint256).max) {
            assertEq(
                assetsIn,
                assetsExpected,
                "Safe mint collateral returned incorrect number of assets compared to expected"
            );
        } else {
            console.log("assetsAfterSafeMintCollateral", assetsIn);
        }
    }

    function _makeSafeWithdrawCollateral(uint256 expectedAssets, uint256 expectedShares) internal virtual {
        if (expectedAssets == type(uint256).max) {
            expectedAssets = ltv.maxWithdrawCollateral(user) / 10;
            console.log("assetsAfterSafeWithdrawCollateral", expectedAssets);
        }

        uint256 shares = ltv.previewWithdrawCollateral(expectedAssets);
        uint256 maxRedeemBefore = ltv.maxRedeemCollateral(user);
        ltv.approve(address(safe4626Collateral), shares);
        uint256 sharesOut = safe4626Collateral.safeWithdrawCollateral(address(ltv), expectedAssets, user, shares);

        assertEq(sharesOut, shares, "Safe withdraw collateral returned incorrect number of shares compared to preview");

        uint256 maxRedeemAfter = ltv.maxRedeemCollateral(user);
        assertGe(
            maxRedeemBefore, maxRedeemAfter + shares, "Safe withdraw collateral should decrease the collateral balance"
        );
        if (expectedShares != type(uint256).max) {
            assertEq(
                sharesOut,
                expectedShares,
                "Safe withdraw collateral returned incorrect number of shares compared to expected"
            );
        } else {
            console.log("sharesAfterSafeWithdrawCollateral", sharesOut);
        }
    }

    function _makeSafeRedeemCollateral(uint256 expectedAssets, uint256 expectedShares) internal virtual {
        if (expectedShares == type(uint256).max) {
            expectedShares = ltv.maxRedeemCollateral(user) / 10;
            console.log("sharesAfterSafeRedeemCollateral", expectedShares);
        }
        uint256 assets = ltv.previewRedeemCollateral(expectedShares);
        uint256 maxRedeemBefore = ltv.maxRedeemCollateral(user);
        ltv.approve(address(safe4626Collateral), expectedShares);
        uint256 assetsOut = safe4626Collateral.safeRedeemCollateral(address(ltv), expectedShares, user, assets);
        assertEq(assetsOut, assets, "Safe redeem collateral returned incorrect number of assets compared to preview");

        uint256 maxRedeemAfter = ltv.maxRedeemCollateral(user);
        assertGe(
            maxRedeemBefore,
            maxRedeemAfter + expectedShares,
            "Safe redeem collateral should decrease the collateral balance"
        );
        if (expectedAssets != type(uint256).max) {
            assertEq(
                assetsOut,
                expectedAssets,
                "Safe redeem collateral returned incorrect number of assets compared to expected"
            );
        } else {
            console.log("assetsAfterSafeRedeemCollateral", assetsOut);
        }
    }

    function _previewMintWithLowLevelRebalance(int256 expectedShares)
        internal
        view
        virtual
        returns (int256 collateralAmount, int256 borrowAmount)
    {
        return ltv.previewLowLevelRebalanceShares(expectedShares);
    }

    function _executeMintWithLowLevelRebalance(int256 expectedShares) internal virtual {
        ltv.executeLowLevelRebalanceShares(expectedShares);
    }

    function _mintWithLowLevelRebalanceApproveTarget() internal view virtual returns (address) {
        return address(ltv);
    }

    function _performMintWithLowLevelRebalance(
        uint256 expectedCollateral,
        uint256 expectedBorrow,
        uint256 expectedShares,
        bytes memory revertReason
    ) internal virtual {
        if (expectedShares == type(uint256).max) {
            assertGt(ltv.maxLowLevelRebalanceShares(), 0, "Max low level rebalance shares should be greater than 0");
            expectedShares = uint256(ltv.maxLowLevelRebalanceShares()) / 10;
            if (revertReason.length == 0) {
                console.log("sharesAfterLowLevelRebalanceDeposit", expectedShares);
            }
        }
        (int256 collateralAmount, int256 borrowAmount) = _previewMintWithLowLevelRebalance(int256(expectedShares));
        require(borrowAmount >= 0, "Borrow amount after low level rebalance deposit should be negative");
        require(collateralAmount >= 0, "Collateral amount after low level rebalance deposit should be positive");

        if (expectedCollateral != type(uint256).max) {
            assertEq(
                uint256(collateralAmount),
                expectedCollateral,
                "Low level rebalance deposit returned incorrect number of collateral compared to expected"
            );
        } else {
            if (revertReason.length == 0) {
                console.log("collateralAfterLowLevelRebalanceDeposit", collateralAmount);
            }
        }
        if (expectedBorrow != type(uint256).max) {
            assertEq(
                uint256(borrowAmount),
                expectedBorrow,
                "Low level rebalance deposit returned incorrect number of borrow compared to expected"
            );
        } else {
            if (revertReason.length == 0) {
                console.log("borrowAfterLowLevelRebalanceDeposit", borrowAmount);
            }
        }

        _receiveCollateralTokens(uint256(collateralAmount));

        collateralToken.approve(_mintWithLowLevelRebalanceApproveTarget(), uint256(collateralAmount));
        uint256 balanceBefore = ltv.balanceOf(user);
        if (revertReason.length > 0) {
            vm.expectRevert(revertReason);
        }
        _executeMintWithLowLevelRebalance(int256(expectedShares));
        if (revertReason.length == 0) {
            assertEq(
                ltv.balanceOf(user),
                balanceBefore + expectedShares,
                "Low level rebalance deposit should increase the balance of the ltv"
            );
        }
    }

    function _previewRedeemWithLowLevelRebalance(int256 expectedShares)
        internal
        view
        virtual
        returns (int256 collateralAmount, int256 borrowAmount)
    {
        return ltv.previewLowLevelRebalanceShares(-int256(expectedShares));
    }

    function _executeRedeemWithLowLevelRebalance(int256 expectedShares) internal virtual {
        ltv.executeLowLevelRebalanceShares(-int256(expectedShares));
    }

    function _redeemWithLowLevelRebalanceApproveTarget() internal view virtual returns (address) {
        return address(ltv);
    }

    function _performRedeemWithLowLevelRebalance(
        uint256 expectedCollateral,
        uint256 expectedBorrow,
        uint256 expectedShares,
        bytes memory revertReason
    ) internal virtual {
        if (expectedShares == type(uint256).max) {
            expectedShares = ltv.balanceOf(user) / 10;
            if (revertReason.length == 0) {
                console.log("sharesAfterLowLevelRebalanceWithdraw", expectedShares);
            }
        }
        (int256 collateralAmount, int256 borrowAmount) = _previewRedeemWithLowLevelRebalance(int256(expectedShares));
        require(collateralAmount <= 0, "Collateral amount after low level rebalance withdraw should be positive");
        require(borrowAmount <= 0, "Borrow amount after low level rebalance withdraw should be negative");
        if (expectedCollateral != type(uint256).max) {
            assertEq(
                uint256(-collateralAmount),
                expectedCollateral,
                "Low level rebalance withdraw returned incorrect number of collateral compared to expected"
            );
        } else {
            if (revertReason.length == 0) {
                console.log("collateralAfterLowLevelRebalanceWithdraw", uint256(-collateralAmount));
            }
        }
        if (expectedBorrow != type(uint256).max) {
            assertEq(
                uint256(-borrowAmount),
                expectedBorrow,
                "Low level rebalance withdraw returned incorrect number of borrow compared to expected"
            );
        } else {
            if (revertReason.length == 0) {
                console.log("borrowAfterLowLevelRebalanceWithdraw", uint256(-borrowAmount));
            }
        }
        _receiveBorrowTokens(uint256(-borrowAmount));
        borrowToken.approve(_redeemWithLowLevelRebalanceApproveTarget(), uint256(-borrowAmount));
        if (_redeemWithLowLevelRebalanceApproveTarget() != address(ltv)) {
            ltv.approve(_redeemWithLowLevelRebalanceApproveTarget(), expectedShares);
        }
        uint256 balanceBefore = ltv.balanceOf(user);
        if (revertReason.length > 0) {
            vm.expectRevert(revertReason);
        }
        _executeRedeemWithLowLevelRebalance(int256(expectedShares));
        if (revertReason.length == 0) {
            assertEq(
                ltv.balanceOf(user),
                balanceBefore - expectedShares,
                "Low level rebalance withdraw should decrease the balance of the ltv"
            );
        }
    }

    function _performFullDepositAuctionExecution(uint256 expectedCollateral, uint256 expectedBorrow) internal virtual {
        if (expectedBorrow == type(uint256).max) {
            assertGt(ltv.futureBorrowAssets(), 0, "Future borrow assets should be greater than 0");
            expectedBorrow = uint256(ltv.futureBorrowAssets());
            console.log("borrowAfterDepositAuctionExecution", expectedBorrow);
        }

        int256 collateralAmount = ltv.previewExecuteAuctionBorrow(-int256(expectedBorrow));
        require(collateralAmount <= 0, "Collateral amount after deposit auction execution should be negative");
        if (expectedCollateral != type(uint256).max) {
            assertEq(
                uint256(-collateralAmount),
                expectedCollateral,
                "Deposit auction execution returned incorrect number of collateral compared to expected"
            );
        } else {
            console.log("collateralAfterDepositAuctionExecution", uint256(-collateralAmount));
        }

        _receiveCollateralTokens(uint256(-collateralAmount));
        collateralToken.approve(address(ltv), uint256(-collateralAmount));
        ltv.executeAuctionBorrow(-int256(expectedBorrow));
        assertEq(ltv.futureBorrowAssets(), 0, "Future borrow assets should be 0 after deposit auction execution");
    }

    function _performFullWithdrawAuctionExecution(uint256 expectedCollateral, uint256 expectedBorrow)
        internal
        virtual
    {
        if (expectedCollateral == type(uint256).max) {
            assertLt(ltv.futureCollateralAssets(), 0, "Future collateral assets should be less than 0");
            expectedCollateral = uint256(-ltv.futureCollateralAssets());
            console.log("collateralAfterWithdrawAuctionExecution", expectedCollateral);
        }

        int256 borrowAmount = ltv.previewExecuteAuctionCollateral(int256(expectedCollateral));
        require(borrowAmount >= 0, "Borrow amount after withdraw auction execution should be positive");
        if (expectedBorrow != type(uint256).max) {
            assertEq(
                uint256(borrowAmount),
                expectedBorrow,
                "Withdraw auction execution returned incorrect number of borrow compared to expected"
            );
        } else {
            console.log("borrowAfterWithdrawAuctionExecution", borrowAmount);
        }
        _receiveBorrowTokens(uint256(borrowAmount));
        borrowToken.approve(address(ltv), uint256(borrowAmount));
        ltv.executeAuctionCollateral(int256(expectedCollateral));
        assertEq(
            ltv.futureCollateralAssets(), 0, "Future collateral assets should be 0 after withdraw auction execution"
        );
    }

    function _receiveCollateralTokens(uint256 collateralAmount) internal virtual {
        deal(address(collateralToken), user, collateralAmount);
    }

    function _receiveBorrowTokens(uint256 borrowAmount) internal virtual {
        deal(address(borrowToken), user, borrowAmount);
    }
}

// forge-lint: disable-end(unsafe-typecast)
