// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../src/interfaces/ILTV.sol";
import "forge-std/interfaces/IERC20.sol";
import {BasicInvariantWrapper} from "./BasicInvariantWrapper.t.sol";

contract LTVVaultWrapper is BasicInvariantWrapper {
    uint256 private totalAssets;
    uint256 private totalSupply;
    
    constructor(ILTV _ltv, address[10] memory _actors) BasicInvariantWrapper(_ltv, _actors) {}

    /// forge-config: default.invariant.fail-on-revert = true
    function deposit(uint256 amount, uint256 receiverIndex, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
        getInvariantsData();
        uint256 maxDeposit = ltv.maxDeposit(currentActor);

        vm.assume(maxDeposit > 0);

        amount = bound(amount, 1, maxDeposit);

        if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < amount) {
            deal(ltv.borrowToken(), currentActor, amount);
        }

        if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < amount) {
            IERC20(ltv.borrowToken()).approve(address(ltv), amount);
        }

        address receiver = actors[bound(receiverIndex, 0, actors.length - 1)];

        ltv.deposit(amount, receiver);
    }

    /// forge-config: default.invariant.fail-on-revert = true
    function withdraw(uint256 amount, uint256 receiverIndex, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
        getInvariantsData();
        uint256 maxWithdraw = ltv.maxWithdraw(currentActor);
        vm.assume(maxWithdraw > 0);

        // amount = bound(amount, 1, maxWithdraw);
        amount = maxWithdraw;

        address receiver = actors[bound(receiverIndex, 0, actors.length - 1)];

        ltv.withdraw(amount, receiver, currentActor);
    }

    /// forge-config: default.invariant.fail-on-revert = true
    function mint(uint256 amount, uint256 receiverIndex, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
        getInvariantsData();
        uint256 maxMint = ltv.maxMint(currentActor);

        vm.assume(maxMint > 0);

        amount = bound(amount, 1, maxMint);

        uint256 assets = ltv.previewMint(amount);
        if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < assets) {
            deal(ltv.borrowToken(), currentActor, assets);
        }

        if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < assets) {
            IERC20(ltv.borrowToken()).approve(address(ltv), assets);
        }

        address receiver = actors[bound(receiverIndex, 0, actors.length - 1)];

        ltv.mint(amount, receiver);
    }

    /// forge-config: default.invariant.fail-on-revert = true
    function redeem(uint256 amount, uint256 receiverIndex, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
        getInvariantsData();
        uint256 maxRedeem = ltv.maxRedeem(currentActor);
        vm.assume(maxRedeem > 0);

        amount = bound(amount, 1, maxRedeem);

        address receiver = actors[bound(receiverIndex, 0, actors.length - 1)];

        ltv.redeem(amount, receiver, currentActor);
    }

    /// forge-config: default.invariant.fail-on-revert = true
    function depositCollateral(uint256 amount, uint256 receiverIndex, uint256 actorIndexSeed)
        public
        useActor(actorIndexSeed)
    {
        getInvariantsData();
        uint256 maxDeposit = ltv.maxDepositCollateral(currentActor);

        vm.assume(maxDeposit > 0);

        amount = bound(amount, 1, maxDeposit);

        if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < amount) {
            deal(ltv.collateralToken(), currentActor, amount);
        }

        if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < amount) {
            IERC20(ltv.collateralToken()).approve(address(ltv), amount);
        }

        address receiver = actors[bound(receiverIndex, 0, actors.length - 1)];

        ltv.depositCollateral(amount, receiver);
    }

    /// forge-config: default.invariant.fail-on-revert = true
    function withdrawCollateral(uint256 amount, uint256 receiverIndex, uint256 actorIndexSeed)
        public
        useActor(actorIndexSeed)
    {
        getInvariantsData();
        uint256 maxWithdraw = ltv.maxWithdrawCollateral(currentActor);
        vm.assume(maxWithdraw > 0);

        // amount = bound(amount, 1, maxWithdraw);
        amount = maxWithdraw;

        address receiver = actors[bound(receiverIndex, 0, actors.length - 1)];

        ltv.withdrawCollateral(amount, receiver, currentActor);
    }

    /// forge-config: default.invariant.fail-on-revert = true
    function mintCollateral(uint256 amount, uint256 receiverIndex, uint256 actorIndexSeed)
        public
        useActor(actorIndexSeed)
    {
        getInvariantsData();
        uint256 maxMint = ltv.maxMintCollateral(currentActor);

        vm.assume(maxMint > 0);

        amount = bound(amount, 1, maxMint);

        uint256 assets = ltv.previewMintCollateral(amount);
        if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < assets) {
            deal(ltv.collateralToken(), currentActor, assets);
        }

        if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < assets) {
            IERC20(ltv.collateralToken()).approve(address(ltv), assets);
        }

        address receiver = actors[bound(receiverIndex, 0, actors.length - 1)];

        ltv.mintCollateral(amount, receiver);
    }

    /// forge-config: default.invariant.fail-on-revert = true
    function redeemCollateral(uint256 amount, uint256 receiverIndex, uint256 actorIndexSeed)
        public
        useActor(actorIndexSeed)
    {
        getInvariantsData();
        uint256 maxRedeem = ltv.maxRedeemCollateral(currentActor);
        vm.assume(maxRedeem > 0);

        amount = bound(amount, 1, maxRedeem);

        address receiver = actors[bound(receiverIndex, 0, actors.length - 1)];

        ltv.redeemCollateral(amount, receiver, currentActor);
    }

    function getInvariantsData() internal override {
        totalAssets = ltv.totalAssets();
        totalSupply = ltv.totalSupply();
    }

    function checkInvariants() public view override {
        assertGe(ltv.totalAssets() * totalSupply, totalAssets * ltv.totalSupply(), "Token price became smaller");
        assertTrue(
            (ltv.futureBorrowAssets() != 0 && ltv.futureCollateralAssets() != 0)
                || ltv.futureCollateralAssets() == ltv.futureBorrowAssets(),
            "Future borrow and collateral assets either both zero or both non-zero"
        );

        assertTrue(
            (ltv.futureBorrowAssets() != 0) || ltv.futureRewardBorrowAssets() != 0,
            "Future borrow or reward borrow assets never zero"
        );
        assertTrue(
            (ltv.futureCollateralAssets() != 0) || ltv.futureRewardCollateralAssets() != 0,
            "Future collateral or reward collateral assets never zero"
        );
    }
}
