// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import "forge-std/Test.sol";

contract LTVVaultWrapper is Test {
    ILTV private ltv;
    address[10] private actors;
    address private currentActor;

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
    }
    
    function deposit(uint256 amount, uint256 receiverIndex, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
        uint256 maxDeposit = ltv.maxDeposit(currentActor);
        
        if (maxDeposit == 0) {
            revert();
        }

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

    function withdraw(uint256 amount, uint256 receiverIndex, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
        uint256 maxWithdraw = ltv.maxWithdraw(currentActor);
        if (maxWithdraw == 0) {
            revert();
        }
        amount = bound(amount, 1, maxWithdraw);

        address receiver = actors[bound(receiverIndex, 0, actors.length - 1)];

        ltv.withdraw(amount, receiver, currentActor);
    }

    function mint(uint256 amount, uint256 receiverIndex, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
        uint256 maxMint = ltv.maxMint(currentActor);
        
        if (maxMint == 0) {
            revert();
        }

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

    function redeem(uint256 amount, uint256 receiverIndex, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
        uint256 maxRedeem = ltv.maxRedeem(currentActor);
        if (maxRedeem == 0) {
            revert();
        }
        amount = bound(amount, 1, maxRedeem);
        
        address receiver = actors[bound(receiverIndex, 0, actors.length - 1)];

        ltv.redeem(amount, receiver, currentActor);
    }
}

contract VaultInvariantTest is BaseTest {
    LTVVaultWrapper wrapper;

    uint256 private initialConvertToAssets;

    function setUp() public {
        BaseTestInit memory init = BaseTestInit({
            owner: address(1),
            guardian: address(2),
            governor: address(3),
            emergencyDeleverager: address(4),
            feeCollector: address(5),
            futureBorrow: 0,
            futureCollateral: 0,
            auctionReward: 0,
            startAuction: 0,
            collateralSlippage: 10 ** 16,
            borrowSlippage: 10 ** 16,
            maxTotalAssetsInUnderlying: type(uint128).max,
            collateralAssets: 2 * 10 ** 19,
            borrowAssets: 35 * 10 ** 18,
            maxSafeLTV: 9 * 10 ** 17,
            minProfitLTV: 5 * 10 ** 17,
            targetLTV: 75 * 10 ** 16,
            maxGrowthFee: 0,
            collateralPrice: 2111111111111111111,
            borrowPrice: 10 ** 18,
            maxDeleverageFee: 0,
            zeroAddressTokens: 20 * 2111111111111111111 - 35 * 10 ** 18
        });

        initializeTest(init);

        initialConvertToAssets = ltv.convertToAssets(10**18);

        address[10] memory actors;
        for (uint256 i = 0; i < 10; i++) {
            actors[i] = address(uint160(i + 1));
        }

        wrapper = new LTVVaultWrapper(ILTV(address(ltv)), actors);
        targetContract(address(wrapper));

        wrapper.mint(1, 0, 0);
    }

    function invariant_vault() public view {
        int256 futureBorrowAssets = ltv.futureBorrowAssets();
        int256 futureRewardBorrowAssets = ltv.futureRewardBorrowAssets();
        int256 realBorrowAssets = int256(ltv.getRealBorrowAssets(true));
        int256 futureCollateralAssets = ltv.futureCollateralAssets();
        int256 futureRewardCollateralAssets = ltv.futureRewardCollateralAssets();
        int256 realCollateralAssets = int256(ltv.getRealCollateralAssets(true));
        console.log("futureBorrowAssets", futureBorrowAssets);
        console.log("futureRewardBorrowAssets", futureRewardBorrowAssets);
        console.log("realBorrowAssets", realBorrowAssets);
        console.log("futureCollateralAssets", futureCollateralAssets * 2111111111111111111 / 10**18);
        console.log("futureRewardCollateralAssets", futureRewardCollateralAssets* 2111111111111111111 / 10**18);
        console.log("realCollateralAssets", realCollateralAssets * 2111111111111111111 / 10**18);
        assertGe(ltv.futureBorrowAssets(), ltv.futureCollateralAssets() * 2111111111111111111 / 10**18 - 3);

        // int256 borrow = (futureBorrowAssets + futureRewardBorrowAssets + realBorrowAssets);
        // int256 collateral = (futureCollateralAssets + futureRewardCollateralAssets + realCollateralAssets) * 2111111111111111111 / 10**18;


        // // assertApproxEqAbs(borrow * 4, collateral * 3, 40);
        // assertLe(borrow * 4, collateral * 3);
    }

    function test_invariant_debug() public view {
        assertEq(ltv.futureBorrowAssets(), ltv.futureCollateralAssets() * 2111111111111111111 / 10**18);
        // int256 futureBorrowAssets = ltv.futureBorrowAssets();
        // int256 futureRewardBorrowAssets = ltv.futureRewardBorrowAssets();
        // int256 realBorrowAssets = int256(ltv.getRealBorrowAssets(true));
        // int256 futureCollateralAssets = ltv.futureCollateralAssets();
        // int256 futureRewardCollateralAssets = ltv.futureRewardCollateralAssets();
        // int256 realCollateralAssets = int256(ltv.getRealCollateralAssets(true));

        // console.log("futureBorrowAssets", futureBorrowAssets * 10**18);
        // console.log("futureRewardBorrowAssets", futureRewardBorrowAssets);
        // console.log("realBorrowAssets", realBorrowAssets);
        // console.log("futureCollateralAssets", futureCollateralAssets);
        // console.log("futureRewardCollateralAssets", futureRewardCollateralAssets);
        // console.log("realCollateralAssets", realCollateralAssets);

        // int256 borrow = (futureBorrowAssets + futureRewardBorrowAssets + realBorrowAssets);
        // int256 collateral = (futureCollateralAssets + futureRewardCollateralAssets + realCollateralAssets) * 2111111111111111111 / 10**18;

        // assertLe(borrow * 4, collateral * 3);
    }
}