// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

contract EuclidianMod {
    function uEuclidianMod(uint256 a, uint256 b) public pure returns (uint256 remainder) {
        require(b != 0, "Division by zero");

        if (a % b == 0) {
            remainder = 0;
        }

        uint256 q = a / b;
        remainder = a - b * q;
    }

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
}
