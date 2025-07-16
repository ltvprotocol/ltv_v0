// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../src/interfaces/ILTV.sol";
import "forge-std/interfaces/IERC20.sol";
import {BasicInvariantWrapper} from "./BasicInvariantWrapper.t.sol";

contract LTVLowLevelWrapper is BasicInvariantWrapper {
    constructor(ILTV _ltv, address[10] memory _actors) BasicInvariantWrapper(_ltv, _actors) {}

    function minLowLevelRebalanceCollateral() internal view returns (int256) {
        int256 userBalance = int256(ltv.balanceOf(currentActor));
        (int256 collateral,) = ltv.previewLowLevelRebalanceShares(-userBalance);
        return collateral;
    }

    function minLowLevelRebalanceBorrow() internal view returns (int256) {
        int256 userBalance = int256(ltv.balanceOf(currentActor));
        (, int256 borrow) = ltv.previewLowLevelRebalanceShares(-userBalance);
        return borrow;
    }

    function executeLowLevelRebalanceBorrow(int256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        external
        useActor(actorIndexSeed) makePostCheck
    {
        moveBlock(blocksDelta);
        int256 maxBorrow = ltv.maxLowLevelRebalanceBorrow();
        int256 minBorrow = minLowLevelRebalanceBorrow();

        vm.assume(maxBorrow >= minBorrow);

        amount = bound(amount, minBorrow, maxBorrow);

        (deltaCollateral, deltaLtv) = ltv.previewLowLevelRebalanceBorrow(amount);
        deltaBorrow = amount;

        if (deltaCollateral > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < uint256(deltaCollateral)) {
                deal(ltv.collateralToken(), currentActor, uint256(deltaCollateral));
            }
            if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < uint256(deltaCollateral)) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(deltaCollateral));
            }
        }

        if (amount < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < uint256(-amount)) {
                deal(ltv.borrowToken(), currentActor, uint256(-amount));
            }
            if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < uint256(-amount)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-amount));
            }
        }

        getInvariantsData();

        ltv.executeLowLevelRebalanceBorrow(amount);
    }

    function executeLowLevelRebalanceBorrowHint(int256 amount, bool hint, uint256 actorIndexSeed, uint256 blocksDelta)
        external
        useActor(actorIndexSeed) makePostCheck
    {
        moveBlock(blocksDelta);
        int256 maxBorrow = ltv.maxLowLevelRebalanceBorrow();
        int256 minBorrow = minLowLevelRebalanceBorrow();

        vm.assume(maxBorrow >= minBorrow);

        amount = bound(amount, minBorrow, maxBorrow);

        (deltaCollateral, deltaLtv) = ltv.previewLowLevelRebalanceBorrowHint(amount, hint);
        deltaBorrow = amount;

        if (deltaCollateral > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < uint256(deltaCollateral)) {
                deal(ltv.collateralToken(), currentActor, uint256(deltaCollateral));
            }
            if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < uint256(deltaCollateral)) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(deltaCollateral));
            }
        }

        if (amount < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < uint256(-amount)) {
                deal(ltv.borrowToken(), currentActor, uint256(-amount));
            }
            if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < uint256(-amount)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-amount));
            }
        }

        getInvariantsData();

        ltv.executeLowLevelRebalanceBorrowHint(amount, hint);
    }

    function executeLowLevelRebalanceCollateral(int256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        external
        useActor(actorIndexSeed) makePostCheck
    {
        moveBlock(blocksDelta);
        int256 maxCollateral = ltv.maxLowLevelRebalanceCollateral();
        int256 minCollateral = minLowLevelRebalanceCollateral();

        vm.assume(maxCollateral >= minCollateral);

        amount = bound(amount, minCollateral, maxCollateral);

        (deltaBorrow, deltaLtv) = ltv.previewLowLevelRebalanceCollateral(amount);
        deltaCollateral = amount;

        if (deltaBorrow < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < uint256(-deltaBorrow)) {
                deal(ltv.borrowToken(), currentActor, uint256(-deltaBorrow));
            }
            if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < uint256(-deltaBorrow)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-deltaBorrow));
            }
        }

        if (amount > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < uint256(deltaCollateral)) {
                deal(ltv.collateralToken(), currentActor, uint256(deltaCollateral));
            }
            if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < uint256(deltaCollateral)) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(deltaCollateral));
            }
        }
        getInvariantsData();

        ltv.executeLowLevelRebalanceCollateral(amount);
    }

    function executeLowLevelRebalanceCollateralHint(
        int256 amount,
        bool hint,
        uint256 actorIndexSeed,
        uint256 blocksDelta
    ) external useActor(actorIndexSeed) makePostCheck {
        moveBlock(blocksDelta);
        int256 maxCollateral = ltv.maxLowLevelRebalanceCollateral();
        int256 minCollateral = minLowLevelRebalanceCollateral();

        vm.assume(maxCollateral >= minCollateral);

        amount = bound(amount, minCollateral, maxCollateral);

        (deltaBorrow, deltaLtv) = ltv.previewLowLevelRebalanceCollateralHint(amount, hint);
        deltaCollateral = amount;

        if (deltaBorrow < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < uint256(-deltaBorrow)) {
                deal(ltv.borrowToken(), currentActor, uint256(-deltaBorrow));
            }
            if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < uint256(-deltaBorrow)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-deltaBorrow));
            }
        }

        if (amount > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < uint256(amount)) {
                deal(ltv.collateralToken(), currentActor, uint256(amount));
            }
            if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < uint256(amount)) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(amount));
            }
        }
        getInvariantsData();

        ltv.executeLowLevelRebalanceCollateralHint(amount, hint);
    }

    function executeLowLevelRebalanceShares(int256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        external
        useActor(actorIndexSeed) makePostCheck
    {
        moveBlock(blocksDelta);
        int256 maxShares = ltv.maxLowLevelRebalanceShares();
        int256 minShares = -int256(ltv.balanceOf(currentActor));

        vm.assume(maxShares >= minShares);

        amount = bound(amount, minShares, maxShares);

        (deltaCollateral, deltaBorrow) = ltv.previewLowLevelRebalanceShares(amount);
        deltaLtv = amount;

        if (deltaCollateral > 0) {
            if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < uint256(deltaCollateral)) {
                deal(ltv.collateralToken(), currentActor, uint256(deltaCollateral));
            }
            if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < uint256(deltaCollateral)) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(deltaCollateral));
            }
        }

        if (deltaBorrow < 0) {
            if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < uint256(-deltaBorrow)) {
                deal(ltv.borrowToken(), currentActor, uint256(-deltaBorrow));
            }
            if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < uint256(-deltaBorrow)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(-deltaBorrow));
            }
        }
        getInvariantsData();

        ltv.executeLowLevelRebalanceShares(amount);
    }
}
