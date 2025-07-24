// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../src/interfaces/ILTV.sol";
import "forge-std/interfaces/IERC20.sol";
import {BaseInvariantWrapper} from "./BaseInvariantWrapper.t.sol";

abstract contract BaseAuctionInvariantWrapper is BaseInvariantWrapper {
    function maxAuctionDeltaUserBorrowAssets() public view returns (int256) {
        if (ltv.futureBorrowAssets() == 0) {
            return 0;
        }
        if (ltv.futureBorrowAssets() > 0) {
            return -ltv.futureBorrowAssets();
        } else {
            return ltv.previewExecuteAuctionCollateral(-ltv.futureCollateralAssets());
        }
    }

    function maxAuctionDeltaUserCollateralAssets() public view returns (int256) {
        if (ltv.futureCollateralAssets() == 0) {
            return 0;
        }
        if (ltv.futureCollateralAssets() < 0) {
            return -ltv.futureCollateralAssets();
        } else {
            return ltv.previewExecuteAuctionBorrow(-ltv.futureBorrowAssets());
        }
    }

    function fuzzExecuteAuctionBorrow(int256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        advanceBlocks(blocksDelta);

        int256 maxDeltaUserBorrowAssets = maxAuctionDeltaUserBorrowAssets();

        vm.assume(maxDeltaUserBorrowAssets != 0);

        if (maxDeltaUserBorrowAssets < 0) {
            amount = bound(amount, maxDeltaUserBorrowAssets, -1);
            int256 collateral = ltv.previewExecuteAuctionBorrow(amount);

            if (IERC20(ltv.collateralToken()).balanceOf(_currentTestActor) < uint256(-collateral)) {
                deal(ltv.collateralToken(), _currentTestActor, uint256(-collateral));
            }

            if (IERC20(ltv.collateralToken()).allowance(_currentTestActor, address(ltv)) < uint256(-collateral)) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(-collateral));
            }
        } else {
            amount = bound(amount, 1, maxDeltaUserBorrowAssets);

            if (IERC20(ltv.borrowToken()).balanceOf(_currentTestActor) < uint256(amount)) {
                deal(ltv.borrowToken(), _currentTestActor, uint256(amount));
            }

            if (IERC20(ltv.borrowToken()).allowance(_currentTestActor, address(ltv)) < uint256(amount)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(amount));
            }
        }

        captureInvariantState();
        _expectedBorrowDelta = -amount;
        _expectedLtvDelta = 0;
        _expectedCollateralDelta = -ltv.executeAuctionBorrow(amount);

        _auctionExecuted = true;
    }

    function fuzzExecuteAuctionCollateral(int256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
        verifyInvariantsAfterOperation
    {
        advanceBlocks(blocksDelta);

        int256 maxDeltaUserCollateralAssets = maxAuctionDeltaUserCollateralAssets();

        vm.assume(maxDeltaUserCollateralAssets != 0);

        if (maxDeltaUserCollateralAssets < 0) {
            amount = bound(amount, maxDeltaUserCollateralAssets, -1);
            int256 borrow = -ltv.previewExecuteAuctionCollateral(amount);

            if (IERC20(ltv.collateralToken()).balanceOf(_currentTestActor) < uint256(borrow)) {
                deal(ltv.collateralToken(), _currentTestActor, uint256(borrow));
            }

            if (IERC20(ltv.collateralToken()).allowance(_currentTestActor, address(ltv)) < uint256(borrow)) {
                IERC20(ltv.collateralToken()).approve(address(ltv), uint256(borrow));
            }
        } else {
            amount = bound(amount, 1, maxDeltaUserCollateralAssets);
            int256 borrow = ltv.previewExecuteAuctionCollateral(amount);

            if (IERC20(ltv.borrowToken()).balanceOf(_currentTestActor) < uint256(borrow)) {
                deal(ltv.borrowToken(), _currentTestActor, uint256(borrow));
            }

            if (IERC20(ltv.borrowToken()).allowance(_currentTestActor, address(ltv)) < uint256(borrow)) {
                IERC20(ltv.borrowToken()).approve(address(ltv), uint256(borrow));
            }
        }

        captureInvariantState();
        _expectedCollateralDelta = -amount;
        _expectedLtvDelta = 0;
        _expectedBorrowDelta = -ltv.executeAuctionCollateral(amount);

        _auctionExecuted = true;
    }
}

contract AuctionInvariantWrapper is BaseAuctionInvariantWrapper {
    constructor(ILTV _ltv, address[10] memory _actors) BaseInvariantWrapper(_ltv, _actors) {}
}
