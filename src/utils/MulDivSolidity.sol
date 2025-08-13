// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

// TODO: refactor to UMulDiv or UnsignedMulDiv
library uMulDivSolidity {
    uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;

    function mulDivDown(uint256 factorA, uint256 factorB, uint256 denominator) internal pure returns (uint256 result) {
        require(denominator != 0, "Denominator cannot be zero");

        if (factorB != 0 && factorA > MAX_UINT256 / factorB) {
            revert("Overflow");
        }
        
       return (factorA * factorB) / denominator;
    }

    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        require(denominator != 0, "Denominator cannot be zero");

        if (y != 0 && x > MAX_UINT256 / y) {
            revert("Overflow");

        }
        
        uint256 addition = 0;
        if ((x * y) % denominator > 0) {
            addition = 1;
        }
           
       return ((x * y) / denominator) + addition;
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
library sMulDivSolidity {
    // Maximum value of a signed 256-bit integer
    int256 internal constant MAX_INT256 = type(int256).max;

    // Minimum value of a signed 256-bit integer
    int256 internal constant MIN_INT256 = type(int256).min;

    function mulDivDown(int256 x, int256 y, int256 denominator) internal pure returns (int256) {
        require(denominator != 0, "Denominator cannot be zero");

        if (y != 0 && x != 0) {
            require(
                (y > 0 && x <= MAX_INT256 / y && x >= MIN_INT256 / y)
                    || (y < 0 && x >= MAX_INT256 / y && x <= MIN_INT256 / y),
                "Multiplication overflow detected"
            );
        }

        // Perform the multiplication
        int256 product = x * y;

        int256 division = product / denominator;
        if (division >= 0) {
            return division;
        }

        if (product % denominator != 0) {
            division -= 1;
        }

        return division;
    }

    function mulDivUp(int256 x, int256 y, int256 denominator) internal pure returns (int256) {
        require(denominator != 0, "Denominator cannot be zero");

        if (y != 0 && x != 0) {
            require(
                (y > 0 && x <= MAX_INT256 / y && x >= MIN_INT256 / y)
                    || (y < 0 && x >= MAX_INT256 / y && x <= MIN_INT256 / y),
                "Multiplication overflow detected"
            );
        }

        // Perform the multiplication
        int256 product = x * y;

        int256 division = product / denominator;

        if (division <= 0) {
            return division;
        }

        if (product % denominator != 0) {
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
