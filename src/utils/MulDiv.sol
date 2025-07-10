// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

// TODO: refactor to UMulDiv or UnsignedMulDiv
library uMulDiv {
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
library sMulDiv {
    // Maximum value of a signed 256-bit integer
    int256 internal constant MAX_INT256 = type(int256).max;

    // Minimum value of a signed 256-bit integer
    int256 internal constant MIN_INT256 = type(int256).min;

    function mulDivDown(int256 x, int256 y, int256 denominator) internal pure returns (int256) {
        require(denominator != 0, "Denominator cannot be zero");

        if (y != 0 && x != 0) {
            if (x > 0 && y > 0) {
                require(x <= MAX_INT256 / y, "Multiplication overflow detected");
            }

            if (x < 0 && y < 0) {
                require(x >= MAX_INT256 / y, "Multiplication overflow detected");
            }

            if (x > 0 && y < 0) {
                // MIN_INT256 / (-1) trick
                require(y >= MIN_INT256 / x, "Multiplication overflow detected");
            }

            if (x < 0 && y > 0) {
                require(x >= MIN_INT256 / y, "Multiplication overflow detected");
            }
        }

        // Perform the multiplication
        int256 product = x * y;

        if (product == MIN_INT256) {
            require(denominator != -1, "Division overflow");
        }

        int256 division = product / denominator;

        // if result is positive, than division returned number rounded towards zero, so mulDivDown is satisfied
        if ((product > 0 && denominator > 0) || (product < 0 && denominator < 0)) {
            return division;
        }

        // if result is negative or zero, than division rounded up, so we need to round down
        if (product % denominator != 0) {

            require(division != MIN_INT256, "Subtraction overflow");

            division -= 1;
        }

        return division;
    }

    function mulDivUp(int256 x, int256 y, int256 denominator) internal pure returns (int256) {
        require(denominator != 0, "Denominator cannot be zero");

        if (y != 0 && x != 0) {
            if (x > 0 && y > 0) {
                require(x <= MAX_INT256 / y, "Multiplication overflow detected");
            }

            if (x < 0 && y < 0) {
                require(x >= MAX_INT256 / y, "Multiplication overflow detected");
            }

            if (x > 0 && y < 0) {
                // MIN_INT256 / (-1) trick
                require(y >= MIN_INT256 / x, "Multiplication overflow detected");
            }

            if (x < 0 && y > 0) {
                require(x >= MIN_INT256 / y, "Multiplication overflow detected");
            }
        }

        // Perform the multiplication
        int256 product = x * y;

        int256 division = product / denominator;

        if (product == MIN_INT256) {
            require(denominator != -1, "Division overflow");
        }

        // if result is negative, than division returned number rounded towards zero, so mulDivUp is satisfied
        if ((product < 0 && denominator > 0) || (product > 0 && denominator < 0)) {
            return division;
        }

        // if result is positive or zero, than division rounded down, so we need to round up
        if (product % denominator != 0) {

            require(division != MAX_INT256, "Addition overflow");

            division += 1;
        }

        return division;
    }

    function mulDiv(int256 x, int256 y, int256 denominator, bool isUp) internal pure returns (int256) {
        if (isUp) {
            return mulDivUp(x, y, denominator);
        } else {
            return mulDivDown(x, y, denominator);
        }
    }
}
