// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../../src/interfaces/ILTV.sol";
import "forge-std/interfaces/IERC20.sol";
import "forge-std/Test.sol";
import "../../../src/Constants.sol";

contract BasicInvariantWrapper is Test {
    ILTV internal ltv;
    address[10] internal actors;
    address internal currentActor;

    uint256 internal totalAssets;
    uint256 internal totalSupply;

    int256 internal borrowUserBalanceBefore;
    int256 internal collateralUserBalanceBefore;
    int256 internal ltvUserBalanceBefore;
    int256 internal deltaBorrow;
    int256 internal deltaCollateral;
    int256 internal deltaLtv;

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

    function getInvariantsData() internal virtual {
        totalAssets = ltv.totalAssets();
        totalSupply = ltv.totalSupply();
        borrowUserBalanceBefore = int256(IERC20(ltv.borrowToken()).balanceOf(currentActor));
        collateralUserBalanceBefore = int256(IERC20(ltv.collateralToken()).balanceOf(currentActor));
        ltvUserBalanceBefore = int256(ltv.balanceOf(currentActor));
    }

    function checkInvariants() public view virtual {
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
    }

    function moveBlock(uint256 blocks) public {
        blocks = bound(blocks, 1, Constants.AMOUNT_OF_STEPS);
        vm.roll(block.number + blocks);
    }
}
