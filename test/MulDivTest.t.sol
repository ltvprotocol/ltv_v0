// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/utils/MulDiv.sol";
import {EuclidianMod} from "./utils/math/EuclidianMod.sol";
import {UnsignedHelpers} from "./helpers/UnsignedHelpers.sol";
import {SignedHelpers} from "./helpers/SignedHelpers.sol";

contract MulDivTest is Test, EuclidianMod, UnsignedHelpers, SignedHelpers {
    /// forge-config: default.allow_internal_expect_revert = true
    function test_uMulDivUpRevertsOnZeroDenominator(uint256 x, uint256 y) public {
        vm.expectRevert(bytes(""));
        uMulDiv.mulDivUp(x, y, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_uMulDivDownRevertsOnZeroDenominator(uint256 x, uint256 y) public {
        vm.expectRevert(bytes(""));
        uMulDiv.mulDivDown(x, y, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_sMulDivUpRevertsOnZeroDenominator(int256 x, int256 y) public {
        vm.expectRevert(bytes(""));
        sMulDiv.mulDivUp(x, y, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_sMulDivDownRevertsOnZeroDenominator(int256 x, int256 y) public {
        vm.expectRevert(bytes(""));
        sMulDiv.mulDivDown(x, y, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_uMulDivUpRevertsOnOverflow(uint256 x, uint256 y, uint256 denominator) public {
        x = uHandleZero(x);
        y = uHandleZero(y);
        denominator = uHandleZero(denominator);

        (x, y) = uFindMulOverflow(x, y);

        vm.expectRevert(bytes(""));
        uMulDiv.mulDivUp(x, y, denominator);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_uMulDivDownRevertsOnOverflow(uint256 x, uint256 y, uint256 denominator) public {
        x = uHandleZero(x);
        y = uHandleZero(y);
        denominator = uHandleZero(denominator);

        (x, y) = uFindMulOverflow(x, y);

        vm.expectRevert(bytes(""));
        uMulDiv.mulDivDown(x, y, denominator);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_sMulDivUpRevertsOnOverflow(int256 x, int256 y, int256 denominator) public {
        x = sHandleZero(x);
        y = sHandleZero(y);
        denominator = sHandleZero(denominator);

        (x, y) = sFindMulOverflow(x, y);

        vm.expectRevert(bytes(""));
        sMulDiv.mulDivUp(x, y, denominator);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_sMulDivDownRevertsOnOverflow(int256 x, int256 y, int256 denominator) public {
        x = sHandleZero(x);
        y = sHandleZero(y);
        denominator = sHandleZero(denominator);

        (x, y) = sFindMulOverflow(x, y);

        vm.expectRevert(bytes(""));
        sMulDiv.mulDivDown(x, y, denominator);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_sMulDivUpDivisionOverflow() public {
        int256 x = type(int256).min;
        int256 y = 1;
        int256 denominator = -1;

        vm.expectRevert(bytes("Division overflow"));
        sMulDiv.mulDivUp(x, y, denominator);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_sMulDivDownDivisionOverflow() public {
        int256 x = type(int256).min;
        int256 y = 1;
        int256 denominator = -1;

        vm.expectRevert(bytes("Division overflow"));
        sMulDiv.mulDivDown(x, y, denominator);
    }

    function test_uMulDivUpZeroWhenXEqZero(uint256 y, uint256 denominator) public pure {
        denominator = uHandleZero(denominator);

        uint256 result = uMulDiv.mulDivUp(0, y, denominator);
        assertEq(result, 0);
    }

    function test_uMulDivUpZeroWhenYEqZero(uint256 x, uint256 denominator) public pure {
        denominator = uHandleZero(denominator);

        uint256 result = uMulDiv.mulDivUp(x, 0, denominator);
        assertEq(result, 0);
    }

    function test_uMulDivDownZeroWhenXEqZero(uint256 y, uint256 denominator) public pure {
        denominator = uHandleZero(denominator);

        uint256 result = uMulDiv.mulDivDown(0, y, denominator);
        assertEq(result, 0);
    }

    function test_uMulDivDownZeroWhenYEqZero(uint256 x, uint256 denominator) public pure {
        denominator = uHandleZero(denominator);

        uint256 result = uMulDiv.mulDivDown(x, 0, denominator);
        assertEq(result, 0);
    }

    function test_sMulDivUpZeroWhenXEqZero(int256 y, int256 denominator) public pure {
        denominator = sHandleZero(denominator);

        int256 result = sMulDiv.mulDivUp(0, y, denominator);
        assertEq(result, 0);
    }

    function test_sMulDivUpZeroWhenYEqZero(int256 x, int256 denominator) public pure {
        denominator = sHandleZero(denominator);

        int256 result = sMulDiv.mulDivUp(x, 0, denominator);
        assertEq(result, 0);
    }

    function test_sMulDivDownZeroWhenXEqZero(int256 y, int256 denominator) public pure {
        denominator = sHandleZero(denominator);

        int256 result = sMulDiv.mulDivDown(0, y, denominator);
        assertEq(result, 0);
    }

    function test_sMulDivDownZeroWhenYEqZero(int256 x, int256 denominator) public pure {
        denominator = sHandleZero(denominator);

        int256 result = sMulDiv.mulDivDown(x, 0, denominator);
        assertEq(result, 0);
    }

    function test_uMulDivUpWithoutRemainder(uint256 x, uint256 y, uint256 denominator) public pure {
        (x, y, denominator) = uFilterInputs(x, y, denominator);
        x = uFindDivisionWithoutRemainder(x, y, denominator);

        uint256 product = x * y;
        uint256 expected = product / denominator;
        uint256 result = uMulDiv.mulDivUp(x, y, denominator);

        assertEq(result, expected);
    }

    function test_uMulDivDownWithoutRemainder(uint256 x, uint256 y, uint256 denominator) public pure {
        (x, y, denominator) = uFilterInputs(x, y, denominator);
        x = uFindDivisionWithoutRemainder(x, y, denominator);

        uint256 product = x * y;
        uint256 expected = product / denominator;
        uint256 result = uMulDiv.mulDivDown(x, y, denominator);

        assertEq(result, expected);
    }

    function test_uMulDivUpWithRemainder(uint256 x, uint256 y, uint256 denominator) public pure {
        (x, y, denominator) = uFilterInputs(x, y, denominator);
        (x, y, denominator) = uFindDivisionWithRemainder(x, y, denominator);

        uint256 result = uMulDiv.mulDivUp(x, y, denominator);
        uint256 remainder = uEuclidianMod(x * y, denominator);
        uint256 expected = (x * y - remainder) / denominator + 1;

        assertEq(result, expected);
        assertEq(result, uMulDiv.mulDivDown(x, y, denominator) + 1);
    }

    function test_uMulDivDownWithRemainder(uint256 x, uint256 y, uint256 denominator) public pure {
        (x, y, denominator) = uFilterInputs(x, y, denominator);
        (x, y, denominator) = uFindDivisionWithRemainder(x, y, denominator);

        uint256 result = uMulDiv.mulDivDown(x, y, denominator);
        uint256 remainder = uEuclidianMod(x * y, denominator);
        uint256 expected = (x * y - remainder) / denominator;

        assertEq(result, expected);
        assertEq(result, uMulDiv.mulDivUp(x, y, denominator) - 1);
    }

    function test_sMulDivUpWithoutRemainder(int256 x, int256 y, int256 denominator) public pure {
        (x, y, denominator) = sFilterInputs(x, y, denominator);
        x = sFindDivisionWithoutRemainder(x, y, denominator);
        (x, y, denominator) = sEliminateDivOverflow(x, y, denominator);

        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        int256 expected = (x * y) / denominator;

        assertEq(result, expected);
        assertEq(result, sMulDiv.mulDivDown(x, y, denominator));
    }

    function test_sMulDivDownWithoutRemainder(int256 x, int256 y, int256 denominator) public pure {
        (x, y, denominator) = sFilterInputs(x, y, denominator);
        x = sFindDivisionWithoutRemainder(x, y, denominator);
        (x, y, denominator) = sEliminateDivOverflow(x, y, denominator);

        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        int256 expected = (x * y) / denominator;

        assertEq(result, expected);
        assertEq(result, sMulDiv.mulDivUp(x, y, denominator));
    }

    function test_sMulDivUpWithRemainderPositiveDenominator(int256 x, int256 y, int256 denominator) public pure {
        denominator = toPositive(denominator);
        (x, y, denominator) = sFilterInputs(x, y, denominator);
        (x, y, denominator) = sFindDivisionWithRemainder(x, y, denominator);

        int256 result = sMulDiv.mulDivUp(x, y, denominator);

        int256 remainder = sEuclidianMod(x * y, denominator);
        int256 expected = (x * y - remainder) / denominator + 1;

        assertEq(result, expected);
    }

    function test_sMulDivUpWithRemainderNegativeDenominator(int256 x, int256 y, int256 denominator) public pure {
        denominator = toNegative(denominator);
        (x, y, denominator) = sFilterInputs(x, y, denominator);
        (x, y, denominator) = sFindDivisionWithRemainder(x, y, denominator);

        int256 result = sMulDiv.mulDivUp(x, y, denominator);

        int256 remainder = sEuclidianMod(x * y, denominator);
        int256 expected = (x * y - remainder) / denominator;

        assertEq(result, expected);
    }

    function test_sMulDivDownWithRemainderPositiveDenominator(int256 x, int256 y, int256 denominator) public pure {
        denominator = toPositive(denominator);
        (x, y, denominator) = sFilterInputs(x, y, denominator);
        (x, y, denominator) = sFindDivisionWithRemainder(x, y, denominator);

        int256 result = sMulDiv.mulDivDown(x, y, denominator);

        int256 remainder = sEuclidianMod(x * y, denominator);
        int256 expected = (x * y - remainder) / denominator;

        assertEq(result, expected);
    }

    function test_sMulDivDownWithRemainderNegativeDenominator(int256 x, int256 y, int256 denominator) public pure {
        denominator = toNegative(denominator);
        (x, y, denominator) = sFilterInputs(x, y, denominator);
        (x, y, denominator) = sFindDivisionWithRemainder(x, y, denominator);

        int256 result = sMulDiv.mulDivDown(x, y, denominator);

        int256 remainder = sEuclidianMod(x * y, denominator);
        int256 expected = (x * y - remainder) / denominator - 1;

        assertEq(result, expected);
    }

    // Special tests for unsigned MulDiv with hardcoded values

    function test_uMulDivUpWithoutRemainderSpecial() public pure {
        uint256 x = 6;
        uint256 y = 2;
        uint256 denominator = 3;
        uint256 result = uMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, 4); // 12 / 3 = 4
    }

    function test_uMulDivUpWithRemainderSpecial() public pure {
        uint256 x = 7;
        uint256 y = 2;
        uint256 denominator = 3;
        uint256 result = uMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, 5); // 14 / 3 = 4.666...
    }

    function test_uMulDivDownWithoutRemainderSpecial() public pure {
        uint256 x = 6;
        uint256 y = 2;
        uint256 denominator = 3;
        uint256 result = uMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, 4); // 12 / 3 = 4
    }

    function test_uMulDivDownWithRemainderSpecial() public pure {
        uint256 x = 7;
        uint256 y = 2;
        uint256 denominator = 3;
        uint256 result = uMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, 4); // 14 / 3 = 4.666...
    }

    // Special tests for signed MulDiv with hardcoded values

    function test_sMulDivUpSamePositiveWithoutRemainderSpecial() public pure {
        int256 x = 6;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, 4); // 12 / 3 = 4
    }

    function test_sMulDivUpSamePositiveWithRemainderSpecial() public pure {
        int256 x = 7;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, 5); // 14 / 3 = 4.666...
    }

    function test_sMulDivDownSamePositiveWithoutRemainderSpecial() public pure {
        int256 x = 6;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, 4); // 12 / 3 = 4
    }

    function test_sMulDivDownSamePositiveWithRemainderSpecial() public pure {
        int256 x = 7;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, 4); // 14 / 3 = 4.666...
    }

    function test_sMulDivUpSecondNegativeWithoutRemainderSpecial() public pure {
        int256 x = 6;
        int256 y = -2;
        int256 denominator = 3;
        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, -4); // -12 / 3 = -4
    }

    function test_sMulDivUpSecondNegativeWithRemainderSpecial() public pure {
        int256 x = 7;
        int256 y = -2;
        int256 denominator = 3;
        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, -4); // -14 / 3 = -4.666...
    }

    function test_sMulDivDownSecondNegativeWithoutRemainderSpecial() public pure {
        int256 x = 6;
        int256 y = -2;
        int256 denominator = 3;
        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, -4); // -12 / 3 = -4
    }

    function test_sMulDivDownSecondNegativeWithRemainderSpecial() public pure {
        int256 x = 7;
        int256 y = -2;
        int256 denominator = 3;
        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, -5); // -14 / 3 = -4.666...
    }

    function test_sMulDivUpSamePositiveWithRemainderNegativeDenominatorSpecial() public pure {
        int256 x = 7;
        int256 y = 2;
        int256 denominator = -3;
        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, -4); // 14 / -3 = -4.666...
    }

    function test_sMulDivDownSamePositiveWithRemainderNegativeDenominatorSpecial() public pure {
        int256 x = 7;
        int256 y = 2;
        int256 denominator = -3;
        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, -5); // 14 / -3 = -4.666...
    }

    function test_sMulDivUpSameNegativeWithRemainderSpecial() public pure {
        int256 x = -7;
        int256 y = -2;
        int256 denominator = 3;
        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, 5); // 14 / 3 = 4.666...
    }

    function test_sMulDivDownSameNegativeWithRemainderSpecial() public pure {
        int256 x = -7;
        int256 y = -2;
        int256 denominator = 3;
        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, 4); // 14 / 3 = 4.666...
    }

    function test_sMulDivUpFirstNegativeWithRemainderNegativeDenominatorSpecial() public pure {
        int256 x = -7;
        int256 y = 2;
        int256 denominator = -3;
        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, 5); // -14 / -3 = 4.666...
    }

    function test_sMulDivDownFirstNegativeWithRemainderNegativeDenominatorSpecial() public pure {
        int256 x = -7;
        int256 y = 2;
        int256 denominator = -3;
        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, 4); // -14 / -3 = 4.666...
    }

    function test_sMulDivUpSecondNegativeWithRemainderNegativeDenominatorSpecial() public pure {
        int256 x = 7;
        int256 y = -2;
        int256 denominator = -3;
        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, 5); // -14 / -3 = 4.666...
    }

    function test_sMulDivDownSecondNegativeWithRemainderNegativeDenominatorSpecial() public pure {
        int256 x = 7;
        int256 y = -2;
        int256 denominator = -3;
        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, 4); // -14 / -3 = 4.666...
    }

    function test_sMulDivUpAllNegativeWithoutRemainderSpecial() public pure {
        int256 x = -6;
        int256 y = -2;
        int256 denominator = -3;
        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, -4); // 12 / -3 = -4
    }

    function test_sMulDivUpFirstNegativeWithoutRemainderSpecial() public pure {
        int256 x = -6;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, -4); // -12 / 3 = -4
    }

    function test_sMulDivUpFirstNegativeWithRemainderSpecial() public pure {
        int256 x = -7;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, -4); // -14 / 3 = -4.666...
    }

    function test_sMulDivDownFirstNegativeWithoutRemainderSpecial() public pure {
        int256 x = -6;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, -4); // -12 / 3 = -4
    }

    function test_sMulDivDownFirstNegativeWithRemainderSpecial() public pure {
        int256 x = -7;
        int256 y = 2;
        int256 denominator = 3;
        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, -5); // -14 / 3 = -4.666...
    }

    function test_sMulDivUpAllNegativeWithRemainderSpecial() public pure {
        int256 x = -7;
        int256 y = -2;
        int256 denominator = -3;
        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        assertEq(result, -4); // 14 / -3 = -4.666...
    }

    function test_sMulDivDownAllNegativeWithoutRemainderSpecial() public pure {
        int256 x = -6;
        int256 y = -2;
        int256 denominator = -3;
        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, -4); // 12 / -3 = -4
    }

    function test_sMulDivDownAllNegativeWithRemainderSpecial() public pure {
        int256 x = -7;
        int256 y = -2;
        int256 denominator = -3;
        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        assertEq(result, -5); // 14 / -3 = -4.666...
    }
}
