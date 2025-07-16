// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../src/interfaces/ILTV.sol";
import "forge-std/interfaces/IERC20.sol";
import {BasicInvariantWrapper} from "./BasicInvariantWrapper.t.sol";

contract LTVVaultWrapper is BasicInvariantWrapper {
    constructor(ILTV _ltv, address[10] memory _actors) BasicInvariantWrapper(_ltv, _actors) {}

    function deposit(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta) public useActor(actorIndexSeed) {
        moveBlock(blocksDelta);
        uint256 maxDeposit = ltv.maxDeposit(currentActor);

        vm.assume(maxDeposit > 0);

        amount = bound(amount, 1, maxDeposit);

        if (IERC20(ltv.borrowToken()).balanceOf(currentActor) < amount) {
            deal(ltv.borrowToken(), currentActor, amount);
        }

        if (IERC20(ltv.borrowToken()).allowance(currentActor, address(ltv)) < amount) {
            IERC20(ltv.borrowToken()).approve(address(ltv), amount);
        }

        getInvariantsData();
        deltaLtv = int256(ltv.deposit(amount, currentActor));
        deltaBorrow = deltaLtv == 0 ? int256(0) : -int256(amount);
        deltaCollateral = 0;
    }

    function withdraw(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta) public useActor(actorIndexSeed) {
        moveBlock(blocksDelta);
        uint256 maxWithdraw = ltv.maxWithdraw(currentActor);
        vm.assume(maxWithdraw > 0);

        amount = bound(amount, 1, maxWithdraw);

        getInvariantsData();
        deltaLtv = -int256(ltv.withdraw(amount, currentActor, currentActor));
        deltaBorrow = deltaLtv == 0 ? int256(0) : int256(amount);
        deltaCollateral = 0;
    }

    function mint(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta) public useActor(actorIndexSeed) {
        moveBlock(blocksDelta);
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

        getInvariantsData();
        deltaBorrow = -int256(ltv.mint(amount, currentActor));
        deltaLtv = deltaBorrow == 0 ? int256(0) : int256(amount);
        deltaCollateral = 0;
    }

    function redeem(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta) public useActor(actorIndexSeed) {
        moveBlock(blocksDelta);
        uint256 maxRedeem = ltv.maxRedeem(currentActor);
        vm.assume(maxRedeem > 0);

        amount = bound(amount, 1, maxRedeem);

        getInvariantsData();
        deltaBorrow = int256(ltv.redeem(amount, currentActor, currentActor));
        deltaLtv = deltaBorrow == 0 ? int256(0) : -int256(amount);
        deltaCollateral = 0;
    }

    function depositCollateral(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
    {
        moveBlock(blocksDelta);
        uint256 maxDeposit = ltv.maxDepositCollateral(currentActor);

        vm.assume(maxDeposit > 0);

        amount = bound(amount, 1, maxDeposit);

        if (IERC20(ltv.collateralToken()).balanceOf(currentActor) < amount) {
            deal(ltv.collateralToken(), currentActor, amount);
        }

        if (IERC20(ltv.collateralToken()).allowance(currentActor, address(ltv)) < amount) {
            IERC20(ltv.collateralToken()).approve(address(ltv), amount);
        }

        getInvariantsData();
        deltaLtv = int256(ltv.depositCollateral(amount, currentActor));
        deltaCollateral = deltaLtv == 0 ? int256(0) : int256(amount);
        deltaBorrow = 0;
    }

    function withdrawCollateral(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
    {
        moveBlock(blocksDelta);
        uint256 maxWithdraw = ltv.maxWithdrawCollateral(currentActor);
        vm.assume(maxWithdraw > 0);

        amount = bound(amount, 1, maxWithdraw);

        getInvariantsData();
        deltaLtv = -int256(ltv.withdrawCollateral(amount, currentActor, currentActor));
        deltaCollateral = deltaLtv == 0 ? int256(0) : -int256(amount);
        deltaBorrow = 0;
    }

    function mintCollateral(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
    {
        moveBlock(blocksDelta);
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

        getInvariantsData();
        deltaCollateral = int256(ltv.mintCollateral(amount, currentActor));
        deltaLtv = deltaCollateral == 0 ? int256(0) : int256(amount);
        deltaBorrow = 0;
    }

    function redeemCollateral(uint256 amount, uint256 actorIndexSeed, uint256 blocksDelta)
        public
        useActor(actorIndexSeed)
    {
        moveBlock(blocksDelta);
        uint256 maxRedeem = ltv.maxRedeemCollateral(currentActor);
        vm.assume(maxRedeem > 0);

        amount = bound(amount, 1, maxRedeem);

        getInvariantsData();
        deltaCollateral = -int256(ltv.redeemCollateral(amount, currentActor, currentActor));
        deltaLtv = deltaCollateral == 0 ? int256(0) : -int256(amount);
        deltaBorrow = 0;
    }

    function checkAndResetInvariants() public override {
        super.checkAndResetInvariants();
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
