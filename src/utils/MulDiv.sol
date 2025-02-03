// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

// TODO: refactor to UMulDiv or UnsignedMulDiv
library uMulDiv {

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    function mulDivDown(
        uint256 factorA,
        uint256 factorB,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        require(denominator != 0, "Denominator cannot be zero");

        /// @solidity memory-safe-assembly
        assembly {
            if iszero(
                mul(
                    denominator,
                    iszero(
                        mul(
                            factorB,
                            gt(
                                factorA,
                                div(
                                    MAX_UINT256,
                                    factorB
                                )
                            )
                        )
                    )
                )
            ) {
                revert(0, 0)
            }

            result := div(
                mul(
                    factorA,
                    factorB
                ),
                denominator
            )
        }
    }
    
    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        require(denominator != 0, "Denominator cannot be zero");
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(
                mul(
                    denominator,
                    iszero(
                        mul(
                            y,
                            gt(
                                x,
                                div(
                                    MAX_UINT256,
                                    y
                                )
                            )
                        )
                    )
                )
            ) {
                revert(0, 0)
            }

            z := add(
                gt(
                    mod(
                        mul(
                            x,
                            y
                        ),
                        denominator
                    ),
                    0
                ),
                div(
                    mul(
                        x,
                        y
                    ),
                    denominator
                )
            )
        }
    }

}

// TODO: refactor to SMulDiv or SignedMulDiv 
library sMulDiv {

    // Maximum value of a signed 256-bit integer
    int256 public constant MAX_INT256 = type(int256).max;

    // Minimum value of a signed 256-bit integer
    int256 public constant MIN_INT256 = type(int256).min;

    function mulDivDown(int256 x, int256 y, int256 denominator) public pure returns (int256) {
        require(denominator != 0, "Denominator cannot be zero");

        if (y != 0 && x != 0) {
            require((y > 0 && x <= MAX_INT256 / y && x >= MIN_INT256 / y) ||
                    (y < 0 && x >= MAX_INT256 / y && x <= MIN_INT256 / y),
                    "Multiplication overflow detected");
        }

        // Perform the multiplication
        int256 product = x * y;

        // If both x and y are positive or negative, result is positive
        // If one is negative and the other positive, result is negative
        if ((x > 0 && y > 0) || (x < 0 && y < 0)) {
            return product / denominator;
        } else {
            // To handle negative results correctly
            int256 division = product / denominator;
            int256 remainder = product % denominator;

            // When x and y have opposite signs, the product is negative
            // If there's a remainder, we adjust the division to round towards zero
            if (remainder != 0) {
                division -= 1;
            }
            return division;
        }
    }

    function mulDivUp(int256 x, int256 y, int256 denominator) public pure returns (int256) {
        require(denominator != 0, "Denominator cannot be zero");

        if (y != 0 && x != 0) {
            require((y > 0 && x <= MAX_INT256 / y && x >= MIN_INT256 / y) ||
                    (y < 0 && x >= MAX_INT256 / y && x <= MIN_INT256 / y),
                    "Multiplication overflow detected");
        }

        // Perform the multiplication
        int256 product = x * y;

        // If both x and y are positive or negative, result is positive
        // If one is negative and the other positive, result is negative
        if ((x > 0 && y > 0) || (x < 0 && y < 0)) {
            // To handle negative results correctly
            int256 division = product / denominator;
            int256 remainder = product % denominator;

            // When x and y have opposite signs, the product is negative
            // If there's a remainder, we adjust the division to round towards zero
            if (remainder != 0) {
                division -= 1;
            }
            return division;
        } else {
            return product / denominator;
        }
    }

}