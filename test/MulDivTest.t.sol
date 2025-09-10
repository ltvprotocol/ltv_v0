// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {UMulDiv, SMulDiv} from "src/math/libraries/MulDiv.sol";
import {EuclidianMod} from "./utils/math/EuclidianMod.sol";
import {UnsignedHelpers} from "./helpers/UnsignedHelpers.sol";
import {SignedHelpers} from "./helpers/SignedHelpers.sol";

contract MulDivTest is Test, EuclidianMod, UnsignedHelpers, SignedHelpers {
    /// forge-config: default.allow_internal_expect_revert = true
    function test_UMulDivUpRevertsOnZeroDenominator(uint256 x, uint256 y) public {
        vm.expectRevert(bytes(""));
        UMulDiv.mulDivUp(x, y, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_UMulDivDownRevertsOnZeroDenominator(uint256 x, uint256 y) public {
        vm.expectRevert(bytes(""));
        UMulDiv.mulDivDown(x, y, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_SMulDivUpRevertsOnZeroDenominator(int256 x, int256 y) public {
        vm.expectRevert(bytes(""));
        SMulDiv.mulDivUp(x, y, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_SMulDivDownRevertsOnZeroDenominator(int256 x, int256 y) public {
        vm.expectRevert(bytes(""));
        SMulDiv.mulDivDown(x, y, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_UMulDivUpRevertsOnOverflow(uint256 x, uint256 y, uint256 denominator) public {
        x = uHandleZero(x);
        y = uHandleZero(y);
        denominator = uHandleZero(denominator);

        (x, y) = uFindMulOverflow(x, y);

        vm.expectRevert(bytes(""));
        UMulDiv.mulDivUp(x, y, denominator);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_UMulDivDownRevertsOnOverflow(uint256 x, uint256 y, uint256 denominator) public {
        x = uHandleZero(x);
        y = uHandleZero(y);
        denominator = uHandleZero(denominator);

        (x, y) = uFindMulOverflow(x, y);

        vm.expectRevert(bytes(""));
        UMulDiv.mulDivDown(x, y, denominator);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_SMulDivUpRevertsOnOverflow(int256 x, int256 y, int256 denominator) public {
        x = sHandleZero(x);
        y = sHandleZero(y);
        denominator = sHandleZero(denominator);

        (x, y) = sFindMulOverflow(x, y);

        vm.expectRevert(bytes(""));
        SMulDiv.mulDivUp(x, y, denominator);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_SMulDivDownRevertsOnOverflow(int256 x, int256 y, int256 denominator) public {
        x = sHandleZero(x);
        y = sHandleZero(y);
        denominator = sHandleZero(denominator);

        (x, y) = sFindMulOverflow(x, y);

        vm.expectRevert(bytes(""));
        SMulDiv.mulDivDown(x, y, denominator);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_SMulDivUpDivisionOverflow() public {
        int256 x = type(int256).min;
        int256 y = 1;
        int256 denominator = -1;

        vm.expectRevert(bytes(""));
        SMulDiv.mulDivUp(x, y, denominator);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_SMulDivDownDivisionOverflow() public {
        int256 x = type(int256).min;
        int256 y = 1;
        int256 denominator = -1;

        vm.expectRevert(bytes(""));
        SMulDiv.mulDivDown(x, y, denominator);
    }

    function test_UMulDivUpZeroWhenXEqZero(uint256 y, uint256 denominator) public pure {
        denominator = uHandleZero(denominator);

        uint256 result = UMulDiv.mulDivUp(0, y, denominator);
        assertEq(result, 0);
    }

    function test_UMulDivUpZeroWhenYEqZero(uint256 x, uint256 denominator) public pure {
        denominator = uHandleZero(denominator);

        uint256 result = UMulDiv.mulDivUp(x, 0, denominator);
        assertEq(result, 0);
    }

    function test_UMulDivDownZeroWhenXEqZero(uint256 y, uint256 denominator) public pure {
        denominator = uHandleZero(denominator);

        uint256 result = UMulDiv.mulDivDown(0, y, denominator);
        assertEq(result, 0);
    }

    function test_UMulDivDownZeroWhenYEqZero(uint256 x, uint256 denominator) public pure {
        denominator = uHandleZero(denominator);

        uint256 result = UMulDiv.mulDivDown(x, 0, denominator);
        assertEq(result, 0);
    }

    function test_SMulDivUpZeroWhenXEqZero(int256 y, int256 denominator) public pure {
        denominator = sHandleZero(denominator);

        int256 result = SMulDiv.mulDivUp(0, y, denominator);
        assertEq(result, 0);
    }

    function test_SMulDivUpZeroWhenYEqZero(int256 x, int256 denominator) public pure {
        denominator = sHandleZero(denominator);

        int256 result = SMulDiv.mulDivUp(x, 0, denominator);
        assertEq(result, 0);
    }

    function test_SMulDivDownZeroWhenXEqZero(int256 y, int256 denominator) public pure {
        denominator = sHandleZero(denominator);

        int256 result = SMulDiv.mulDivDown(0, y, denominator);
        assertEq(result, 0);
    }

    function test_SMulDivDownZeroWhenYEqZero(int256 x, int256 denominator) public pure {
        denominator = sHandleZero(denominator);

        int256 result = SMulDiv.mulDivDown(x, 0, denominator);
        assertEq(result, 0);
    }

    function test_UMulDivUpWithoutRemainder(uint256 x, uint256 y, uint256 denominator) public pure {
        (x, y, denominator) = uFilterInputs(x, y, denominator);
        x = uFindDivisionWithoutRemainder(x, y, denominator);

        uint256 product = x * y;
        uint256 expected = product / denominator;
        uint256 result = UMulDiv.mulDivUp(x, y, denominator);

        assertEq(result, expected);
    }

    function test_UMulDivDownWithoutRemainder(uint256 x, uint256 y, uint256 denominator) public pure {
        (x, y, denominator) = uFilterInputs(x, y, denominator);
        x = uFindDivisionWithoutRemainder(x, y, denominator);

        uint256 product = x * y;
        uint256 expected = product / denominator;
        uint256 result = UMulDiv.mulDivDown(x, y, denominator);

        assertEq(result, expected);
    }

    function test_UMulDivUpWithRemainder(uint256 x, uint256 y, uint256 denominator) public pure {
        (x, y, denominator) = uFilterInputs(x, y, denominator);
        (x, y, denominator) = uFindDivisionWithRemainder(x, y, denominator);

        uint256 result = UMulDiv.mulDivUp(x, y, denominator);
        uint256 remainder = uEuclidianMod(x * y, denominator);
        uint256 expected = (x * y - remainder) / denominator + 1;

        assertEq(result, expected);
        assertEq(result, UMulDiv.mulDivDown(x, y, denominator) + 1);
    }

    function test_UMulDivDownWithRemainder(uint256 x, uint256 y, uint256 denominator) public pure {
        (x, y, denominator) = uFilterInputs(x, y, denominator);
        (x, y, denominator) = uFindDivisionWithRemainder(x, y, denominator);

        uint256 result = UMulDiv.mulDivDown(x, y, denominator);
        uint256 remainder = uEuclidianMod(x * y, denominator);
        uint256 expected = (x * y - remainder) / denominator;

        assertEq(result, expected);
        assertEq(result, UMulDiv.mulDivUp(x, y, denominator) - 1);
    }

    function test_SMulDivUpWithoutRemainder(int256 x, int256 y, int256 denominator) public pure {
        (x, y, denominator) = sFilterInputs(x, y, denominator);
        x = sFindDivisionWithoutRemainder(x, y, denominator);
        (x, y, denominator) = sEliminateDivOverflow(x, y, denominator);

        int256 result = SMulDiv.mulDivUp(x, y, denominator);
        int256 expected = (x * y) / denominator;

        assertEq(result, expected);
        assertEq(result, SMulDiv.mulDivDown(x, y, denominator));
    }

    function test_SMulDivDownWithoutRemainder(int256 x, int256 y, int256 denominator) public pure {
        (x, y, denominator) = sFilterInputs(x, y, denominator);
        x = sFindDivisionWithoutRemainder(x, y, denominator);
        (x, y, denominator) = sEliminateDivOverflow(x, y, denominator);

        int256 result = SMulDiv.mulDivDown(x, y, denominator);
        int256 expected = (x * y) / denominator;

        assertEq(result, expected);
        assertEq(result, SMulDiv.mulDivUp(x, y, denominator));
    }

    function test_SMulDivUpWithRemainderPositiveDenominator(int256 x, int256 y, int256 denominator) public pure {
        denominator = toPositive(denominator);
        (x, y, denominator) = sFilterInputs(x, y, denominator);
        (x, y, denominator) = sFindDivisionWithRemainder(x, y, denominator);

        int256 result = SMulDiv.mulDivUp(x, y, denominator);

        int256 remainder = sEuclidianMod(x * y, denominator);
        int256 expected = (x * y - remainder) / denominator + 1;

        assertEq(result, expected);
    }

    function test_SMulDivUpWithRemainderNegativeDenominator(int256 x, int256 y, int256 denominator) public pure {
        denominator = toNegative(denominator);
        (x, y, denominator) = sFilterInputs(x, y, denominator);
        (x, y, denominator) = sFindDivisionWithRemainder(x, y, denominator);

        int256 result = SMulDiv.mulDivUp(x, y, denominator);

        int256 remainder = sEuclidianMod(x * y, denominator);
        int256 expected = (x * y - remainder) / denominator;

        assertEq(result, expected);
    }

    function test_SMulDivDownWithRemainderPositiveDenominator(int256 x, int256 y, int256 denominator) public pure {
        denominator = toPositive(denominator);
        (x, y, denominator) = sFilterInputs(x, y, denominator);
        (x, y, denominator) = sFindDivisionWithRemainder(x, y, denominator);

        int256 result = SMulDiv.mulDivDown(x, y, denominator);

        int256 remainder = sEuclidianMod(x * y, denominator);
        int256 expected = (x * y - remainder) / denominator;

        assertEq(result, expected);
    }

    function test_SMulDivDownWithRemainderNegativeDenominator(int256 x, int256 y, int256 denominator) public pure {
        denominator = toNegative(denominator);
        (x, y, denominator) = sFilterInputs(x, y, denominator);
        (x, y, denominator) = sFindDivisionWithRemainder(x, y, denominator);

        int256 result = SMulDiv.mulDivDown(x, y, denominator);

        int256 remainder = sEuclidianMod(x * y, denominator);
        int256 expected = (x * y - remainder) / denominator - 1;

        assertEq(result, expected);
    }

    // Special tests for unsigned MulDiv with hardcoded values

    function test_UMulDivUpWithoutRemainderSpecial() public pure {
        uint256 x = 6;
        uint256 y = 2;
        uint256 denominator = 3;
        uint256 result = UMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, 4); // 12 / 3 = 4
    }

    function test_UMulDivUpWithRemainderSpecial() public pure {
        uint256 x = 7;
        uint256 y = 2;
        uint256 denominator = 3;
        uint256 result = UMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, 5); // 14 / 3 = 4.666...
    }

    function test_UMulDivDownWithoutRemainderSpecial() public pure {
        uint256 x = 6;
        uint256 y = 2;
        uint256 denominator = 3;
        uint256 result = UMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, 4); // 12 / 3 = 4
    }

    function test_UMulDivDownWithRemainderSpecial() public pure {
        uint256 x = 7;
        uint256 y = 2;
        uint256 denominator = 3;
        uint256 result = UMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, 4); // 14 / 3 = 4.666...
    }

    // Special tests for signed MulDiv with hardcoded values

    function test_SMulDivUpSamePositiveWithoutRemainderSpecial() public pure {
        int256 x = 6;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = SMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, 4); // 12 / 3 = 4
    }

    function test_SMulDivUpSamePositiveWithRemainderSpecial() public pure {
        int256 x = 7;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = SMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, 5); // 14 / 3 = 4.666...
    }

    function test_SMulDivDownSamePositiveWithoutRemainderSpecial() public pure {
        int256 x = 6;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = SMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, 4); // 12 / 3 = 4
    }

    function test_SMulDivDownSamePositiveWithRemainderSpecial() public pure {
        int256 x = 7;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = SMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, 4); // 14 / 3 = 4.666...
    }

    function test_SMulDivUpSecondNegativeWithoutRemainderSpecial() public pure {
        int256 x = 6;
        int256 y = -2;
        int256 denominator = 3;
        int256 result = SMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, -4); // -12 / 3 = -4
    }

    function test_SMulDivUpSecondNegativeWithRemainderSpecial() public pure {
        int256 x = 7;
        int256 y = -2;
        int256 denominator = 3;
        int256 result = SMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, -4); // -14 / 3 = -4.666...
    }

    function test_SMulDivDownSecondNegativeWithoutRemainderSpecial() public pure {
        int256 x = 6;
        int256 y = -2;
        int256 denominator = 3;
        int256 result = SMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, -4); // -12 / 3 = -4
    }

    function test_SMulDivDownSecondNegativeWithRemainderSpecial() public pure {
        int256 x = 7;
        int256 y = -2;
        int256 denominator = 3;
        int256 result = SMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, -5); // -14 / 3 = -4.666...
    }

    function test_SMulDivUpSamePositiveWithRemainderNegativeDenominatorSpecial() public pure {
        int256 x = 7;
        int256 y = 2;
        int256 denominator = -3;
        int256 result = SMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, -4); // 14 / -3 = -4.666...
    }

    function test_SMulDivDownSamePositiveWithRemainderNegativeDenominatorSpecial() public pure {
        int256 x = 7;
        int256 y = 2;
        int256 denominator = -3;
        int256 result = SMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, -5); // 14 / -3 = -4.666...
    }

    function test_SMulDivUpSameNegativeWithRemainderSpecial() public pure {
        int256 x = -7;
        int256 y = -2;
        int256 denominator = 3;
        int256 result = SMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, 5); // 14 / 3 = 4.666...
    }

    function test_SMulDivDownSameNegativeWithRemainderSpecial() public pure {
        int256 x = -7;
        int256 y = -2;
        int256 denominator = 3;
        int256 result = SMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, 4); // 14 / 3 = 4.666...
    }

    function test_SMulDivUpFirstNegativeWithRemainderNegativeDenominatorSpecial() public pure {
        int256 x = -7;
        int256 y = 2;
        int256 denominator = -3;
        int256 result = SMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, 5); // -14 / -3 = 4.666...
    }

    function test_SMulDivDownFirstNegativeWithRemainderNegativeDenominatorSpecial() public pure {
        int256 x = -7;
        int256 y = 2;
        int256 denominator = -3;
        int256 result = SMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, 4); // -14 / -3 = 4.666...
    }

    function test_SMulDivUpSecondNegativeWithRemainderNegativeDenominatorSpecial() public pure {
        int256 x = 7;
        int256 y = -2;
        int256 denominator = -3;
        int256 result = SMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, 5); // -14 / -3 = 4.666...
    }

    function test_SMulDivDownSecondNegativeWithRemainderNegativeDenominatorSpecial() public pure {
        int256 x = 7;
        int256 y = -2;
        int256 denominator = -3;
        int256 result = SMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, 4); // -14 / -3 = 4.666...
    }

    function test_SMulDivUpAllNegativeWithoutRemainderSpecial() public pure {
        int256 x = -6;
        int256 y = -2;
        int256 denominator = -3;
        int256 result = SMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, -4); // 12 / -3 = -4
    }

    function test_SMulDivUpFirstNegativeWithoutRemainderSpecial() public pure {
        int256 x = -6;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = SMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, -4); // -12 / 3 = -4
    }

    function test_SMulDivUpFirstNegativeWithRemainderSpecial() public pure {
        int256 x = -7;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = SMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, -4); // -14 / 3 = -4.666...
    }

    function test_SMulDivDownFirstNegativeWithoutRemainderSpecial() public pure {
        int256 x = -6;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = SMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, -4); // -12 / 3 = -4
    }

    function test_SMulDivDownFirstNegativeWithRemainderSpecial() public pure {
        int256 x = -7;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = SMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, -5); // -14 / 3 = -4.666...
    }

    function test_SMulDivUpAllNegativeWithRemainderSpecial() public pure {
        int256 x = -7;
        int256 y = -2;
        int256 denominator = -3;
        int256 result = SMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, -4); // 14 / -3 = -4.666...
    }

    function test_SMulDivDownAllNegativeWithoutRemainderSpecial() public pure {
        int256 x = -6;
        int256 y = -2;
        int256 denominator = -3;
        int256 result = SMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, -4); // 12 / -3 = -4
    }

    function test_SMulDivDownAllNegativeWithRemainderSpecial() public pure {
        int256 x = -7;
        int256 y = -2;
        int256 denominator = -3;
        int256 result = SMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, -5); // 14 / -3 = -4.666...
    }
}
