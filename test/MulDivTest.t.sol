// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/utils/MulDiv.sol";

contract MulDivTest is Test {
    /// forge-config: default.allow_internal_expect_revert = true
    function test_uMulDivUpRevertsOnZeroDenominator(uint256 x, uint256 y) public {
        vm.expectRevert(bytes("Denominator cannot be zero"));
        uMulDiv.mulDivUp(x, y, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_uMulDivDownRevertsOnZeroDenominator(uint256 x, uint256 y) public {
        vm.expectRevert(bytes("Denominator cannot be zero"));
        uMulDiv.mulDivDown(x, y, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_sMulDivUpRevertsOnZeroDenominator(int256 x, int256 y) public {
        vm.expectRevert(bytes("Denominator cannot be zero"));
        sMulDiv.mulDivUp(x, y, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_sMulDivDownRevertsOnZeroDenominator(int256 x, int256 y) public {
        vm.expectRevert(bytes("Denominator cannot be zero"));
        sMulDiv.mulDivDown(x, y, 0);
    }

    function test_uMulDivUpZeroWhenXEqZero(uint256 y, uint256 denominator) public pure {
        vm.assume(denominator != 0);

        uint256 result = uMulDiv.mulDivUp(0, y, denominator);
        assertEq(result, 0);
    }

    function test_uMulDivUpZeroWhenYEqZero(uint256 x, uint256 denominator) public pure {
        vm.assume(denominator != 0);

        uint256 result = uMulDiv.mulDivUp(x, 0, denominator);
        assertEq(result, 0);
    }

    function test_uMulDivDownZeroWhenXEqZero(uint256 y, uint256 denominator) public pure {
        vm.assume(denominator != 0);

        uint256 result = uMulDiv.mulDivDown(0, y, denominator);
        assertEq(result, 0);
    }

    function test_uMulDivDownZeroWhenYEqZero(uint256 x, uint256 denominator) public pure {
        vm.assume(denominator != 0);

        uint256 result = uMulDiv.mulDivDown(x, 0, denominator);
        assertEq(result, 0);
    }

    function test_sMulDivUpZeroWhenXEqZero(int256 y, int256 denominator) public pure {
        vm.assume(denominator != 0);

        int256 result = sMulDiv.mulDivUp(0, y, denominator);
        assertEq(result, 0);
    }

    function test_sMulDivUpZeroWhenYEqZero(int256 x, int256 denominator) public pure {
        vm.assume(denominator != 0);

        int256 result = sMulDiv.mulDivUp(x, 0, denominator);
        assertEq(result, 0);
    }

    function test_sMulDivDownZeroWhenXEqZero(int256 y, int256 denominator) public pure {
        vm.assume(denominator != 0);

        int256 result = sMulDiv.mulDivDown(0, y, denominator);
        assertEq(result, 0);
    }

    function test_sMulDivDownZeroWhenYEqZero(int256 x, int256 denominator) public pure {
        vm.assume(denominator != 0);

        int256 result = sMulDiv.mulDivDown(x, 0, denominator);
        assertEq(result, 0);
    }

    function uEuclidianMod(uint256 a, uint256 b) public pure returns (uint256 remainder) {
        require(b != 0, "Division by zero");

        if (a % b == 0) {
            remainder = 0;
        }

        uint256 q = a / b;
        remainder = a - b * q;
    }

    // not used in tests right now, I did not removed this, maybe it's can be used in the future
    function sEuclidianMod(int256 a, int256 b) public pure returns (int256 remainder) {
        require(b != 0, "Division by zero");

        remainder = a % b;
        if (remainder < 0) {
            if (b > 0) {
                remainder += b;
            } else {
                remainder -= b;
            }
        }
    }

    function assumeUMulDivInputs(uint256 x, uint256 y, uint256 denominator) public pure {
        vm.assume(denominator != 0);
        vm.assume(x != 0);
        vm.assume(y != 0);
        vm.assume(x <= type(uint256).max / y);
    }

    function test_uMulDivUpWithoutRemainder(uint256 x, uint256 y, uint256 denominator) public pure {
        assumeUMulDivInputs(x, y, denominator);
        vm.assume((x * y) % denominator == 0);

        uint256 result = uMulDiv.mulDivUp(x, y, denominator);
        uint256 expected = (x * y) / denominator;

        assertEq(result, expected);
        assertEq(result, uMulDiv.mulDivDown(x, y, denominator));
    }

    function test_uMulDivDownWithoutRemainder(uint256 x, uint256 y, uint256 denominator) public pure {
        assumeUMulDivInputs(x, y, denominator);
        vm.assume((x * y) % denominator == 0);

        uint256 result = uMulDiv.mulDivDown(x, y, denominator);
        uint256 expected = (x * y) / denominator;

        assertEq(result, expected);
        assertEq(result, uMulDiv.mulDivUp(x, y, denominator));
    }

    function test_uMulDivUpWithRemainder(uint256 x, uint256 y, uint256 denominator) public pure {
        assumeUMulDivInputs(x, y, denominator);
        vm.assume((x * y) % denominator != 0);

        uint256 result = uMulDiv.mulDivUp(x, y, denominator);
        uint256 remainder = uEuclidianMod(x * y, denominator);
        uint256 expected = (x * y - remainder) / denominator + 1;

        assertEq(result, expected);
        assertEq(result, uMulDiv.mulDivDown(x, y, denominator) + 1);
    }

    function test_uMulDivDownWithRemainder(uint256 x, uint256 y, uint256 denominator) public pure {
        assumeUMulDivInputs(x, y, denominator);
        vm.assume((x * y) % denominator != 0);

        uint256 result = uMulDiv.mulDivDown(x, y, denominator);
        uint256 remainder = uEuclidianMod(x * y, denominator);
        uint256 expected = (x * y - remainder) / denominator;

        assertEq(result, expected);
        assertEq(result, uMulDiv.mulDivUp(x, y, denominator) - 1);
    }

    function assumeSMulDivInputs(int256 x, int256 y, int256 denominator) public pure {
        vm.assume(denominator != 0);
        vm.assume(x != 0);
        vm.assume(y != 0);
        vm.assume(x != type(int256).min);
        vm.assume(x != type(int256).max);
        vm.assume(y != -1);

        unchecked {
            int256 product = x * y;
            vm.assume(y == 0 || product / y == x);
        }
    }

    function test_sMulDivUpWithoutRemainder(int256 x, int256 y, int256 denominator) public pure {
        assumeSMulDivInputs(x, y, denominator);
        vm.assume((x * y) % denominator == 0);

        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        int256 expected = (x * y) / denominator;

        assertEq(result, expected);
        assertEq(result, sMulDiv.mulDivDown(x, y, denominator));
    }

    function test_sMulDivDownWithoutRemainder(int256 x, int256 y, int256 denominator) public pure {
        assumeSMulDivInputs(x, y, denominator);
        vm.assume((x * y) % denominator == 0);

        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        int256 expected = (x * y) / denominator;

        assertEq(result, expected);
        assertEq(result, sMulDiv.mulDivUp(x, y, denominator));
    }

    function isPositiveProduct(int256 a, int256 b, int256 c) internal pure returns (bool) {
        uint8 negativeCount = 0;

        if (a < 0) negativeCount++;
        if (b < 0) negativeCount++;
        if (c < 0) negativeCount++;

        return negativeCount % 2 == 0;
    }

    function test_sMulDivUpWithRemainderPositiveProduct(int256 x, int256 y, int256 denominator) public pure {
        assumeSMulDivInputs(x, y, denominator);
        vm.assume((x * y) % denominator != 0);
        vm.assume(isPositiveProduct(x, y, denominator));

        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        int256 expected = (x * y) / denominator + 1;

        assertEq(result, expected);
    }

    function test_sMulDivDownWithRemainderPositiveProduct(int256 x, int256 y, int256 denominator) public pure {
        assumeSMulDivInputs(x, y, denominator);
        vm.assume((x * y) % denominator != 0);
        vm.assume(isPositiveProduct(x, y, denominator));

        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        int256 expected = (x * y) / denominator;

        assertEq(result, expected);
    }

    function test_sMulDivUpWithRemainderNegativeProduct(int256 x, int256 y, int256 denominator) public pure {
        assumeSMulDivInputs(x, y, denominator);
        vm.assume((x * y) % denominator != 0);
        vm.assume(!isPositiveProduct(x, y, denominator));

        int256 result = sMulDiv.mulDivUp(x, y, denominator);
        int256 expected = (x * y) / denominator;

        if (expected == 0) {
            expected++;
        }

        assertEq(result, expected);
    }

    function test_sMulDivDownWithRemainderNegativeProduct(int256 x, int256 y, int256 denominator) public pure {
        assumeSMulDivInputs(x, y, denominator);
        vm.assume((x * y) % denominator != 0);
        vm.assume(!isPositiveProduct(x, y, denominator));

        int256 result = sMulDiv.mulDivDown(x, y, denominator);
        int256 expected = (x * y) / denominator;

        if (expected != 0) {
            expected--;
        }

        assertEq(result, expected);
    }
}
