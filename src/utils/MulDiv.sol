// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

// TODO: refactor to UMulDiv or UnsignedMulDiv
library uMulDiv {
    uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;

    function mulDivDown(uint256 factorA, uint256 factorB, uint256 denominator) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(mul(denominator, iszero(mul(factorB, gt(factorA, div(MAX_UINT256, factorB)))))) { revert(0, 0) }

            result := div(mul(factorA, factorB), denominator)
        }
    }

    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
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
library sMulDiv {
    // Maximum value of a signed 256-bit integer
    int256 internal constant MAX_INT256 = type(int256).max;

    // Minimum value of a signed 256-bit integer
    int256 internal constant MIN_INT256 = type(int256).min;

    function mulDivDown(int256 x, int256 y, int256 denominator) internal pure returns (int256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Early return for zero denominator
            if iszero(denominator) { revert(0, 0) }

            // Early return for zero inputs
            let anyZero := or(iszero(x), iszero(y))
            if anyZero { result := 0 }

            if iszero(anyZero) {
                // Perform multiplication
                let product := mul(x, y)
                if eq(product, 0x8000000000000000000000000000000000000000000000000000000000000000) {
                    if or(
                        eq(y, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
                        eq(denominator, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                    ) { revert(0, 0) }
                }
                if iszero(eq(x, sdiv(product, y))) { revert(0, 0) }

                // Perform division
                let division := sdiv(product, denominator)

                // Determine if result should be positive or negative
                let shouldBeNegative := xor(shr(255, product), shr(255, denominator))

                if shouldBeNegative {
                    // Result should be negative, check if we need to round down
                    if smod(product, denominator) { division := sub(division, 1) }
                }

                result := division
            }
        }
    }

    function mulDivUp(int256 x, int256 y, int256 denominator) internal pure returns (int256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Early return for zero denominator
            if iszero(denominator) { revert(0, 0) }

            // Early return for zero inputs
            let anyZero := or(iszero(x), iszero(y))
            if anyZero { result := 0 }

            if iszero(anyZero) {
                // Perform multiplication
                let product := mul(x, y)
                if eq(product, 0x8000000000000000000000000000000000000000000000000000000000000000) {
                    if or(
                        eq(y, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
                        eq(denominator, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                    ) { revert(0, 0) }
                }
                if iszero(eq(x, sdiv(product, y))) { revert(0, 0) }

                // Perform division
                let division := sdiv(product, denominator)

                // Determine if result should be positive or negative
                let shouldBePositive := eq(shr(255, product), shr(255, denominator))

                if shouldBePositive {
                    // Result should be negative, check if we need to round down
                    if smod(product, denominator) { division := add(division, 1) }
                }

                result := division
            }
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
