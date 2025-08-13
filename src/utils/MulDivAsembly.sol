// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

// TODO: refactor to UMulDiv or UnsignedMulDiv
library uMulDivAsembly {
    uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;

    function mulDivDown(uint256 factorA, uint256 factorB, uint256 denominator) internal pure returns (uint256 result) {
        require(denominator != 0, "Denominator cannot be zero");

        /// @solidity memory-safe-assembly
        assembly {
            if iszero(mul(denominator, iszero(mul(factorB, gt(factorA, div(MAX_UINT256, factorB)))))) { revert(0, 0) }

            result := div(mul(factorA, factorB), denominator)
        }
    }

    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        require(denominator != 0, "Denominator cannot be zero");

        /// @solidity memory-safe-assembly
        assembly {
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) { revert(0, 0) }

            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function mulDiv(uint256 x, uint256 y, uint256 denominator, bool isUp) internal pure returns (uint256) {
        if (isUp) {
            return mulDivUp(x, y, denominator);
        } else {
            return mulDivDown(x, y, denominator);
        }
    }
}

// TODO: refactor to SMulDiv or SignedMulDiv
library sMulDivAsembly {
    // Maximum value of a signed 256-bit integer
    // int256 internal constant MAX_INT256 = type(int256).max;
    int256 internal constant MAX_INT256 = 2**255 - 1;

    // Minimum value of a signed 256-bit integer
    // int256 internal constant MIN_INT256 = type(int256).min;
    int256 internal constant MIN_INT256 = -2**255;

    function mulDivDown(int256 x, int256 y, int256 denominator) internal pure returns (int256 result) {
        require(denominator != 0, "Denominator cannot be zero");

        assembly {
            if or(iszero(y), iszero(x)) {
                result := 0
                return(0, 32)
            }

            // Overflow checks
            if and(and(sgt(x, 0), sgt(y, 0)), sgt(x, div(MAX_INT256, y))) { revert(0, 0) }
            if and(and(slt(x, 0), slt(y, 0)), slt(x, div(MAX_INT256, y))) { revert(0, 0) }
            if and(and(sgt(x, 0), slt(y, 0)), slt(y, div(MIN_INT256, x))) { revert(0, 0) }
            if and(and(slt(x, 0), sgt(y, 0)), slt(x, div(MIN_INT256, y))) { revert(0, 0) }

            let prod := mul(x, y)

            // MIN_INT / -1 case
            if and(eq(prod, MIN_INT256), eq(denominator, sub(0, 1))) { revert(0, 0) }

            let division := div(prod, denominator)

            if iszero(smod(prod, denominator)) {
                result := division
                return(0, 32)
            }

            // Overflow on subtraction
            if eq(division, MIN_INT256) { revert(0, 0) }

            result := sub(division, 1)
        }
    }

    function mulDivUp(int256 x, int256 y, int256 denominator) internal pure returns (int256 result) {
        require(denominator != 0, "Denominator cannot be zero");

        assembly {

            // Overflow check: mulmod wraps exactly like full 256-bit MUL.
            // If (x * y) mod 2²⁵⁶ ≠ x * y in signed space AND signs agree, overflow.
            let product := mul(x, y)
            let wrap := mulmod(x, y, not(0))
            if and(eq(wrap, product),                // unsigned equality
                   xor(slt(product,0), xor(slt(x,0), slt(y,0)))) { }
            // else revert on overflow
            if iszero(eq(wrap, product)) {
                // signs of operands equal ⇒ overflow
                if iszero(xor(slt(x,0), slt(y,0))) { revert(0,0) }
            }

            if and(eq(product, MIN_INT256), eq(denominator, sub(0,1))) { revert(0,0) }
            let q := sdiv(product, denominator)
            if iszero(xor(slt(product,0), slt(denominator,0))) {
                if iszero(iszero(smod(product, denominator))) {
                    if eq(q, MAX_INT256) { revert(0,0) }
                    q := add(q, 1)
                }
            }
            result := q
        }
    }

    function mulDiv(int256 x, int256 y, int256 denominator, bool isUp) internal pure returns (int256) {
        if (isUp) {
            return mulDivUp(x, y, denominator);
        } else {
            return mulDivDown(x, y, denominator);
        }
    }
}
