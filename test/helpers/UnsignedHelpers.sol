// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

contract UnsignedHelpers {
    uint256 constant UINT_MAX = type(uint256).max;

    function uHandleZero(uint256 num) public pure returns (uint256) {
        return num = num == 0 ? 1 : num;
    }

    function uEliminateMulOverflow(uint256 x, uint256 y) public pure returns (uint256) {
        uint256 maxDivY = UINT_MAX / y;

        if (x > maxDivY) {
            return maxDivY - 1;
        }

        return x;
    }

    function uFindMulOverflow(uint256 x, uint256 y) public pure returns (uint256, uint256) {
        if (x == 1 || y == 1) {
            return (2, UINT_MAX);
        }

        uint256 maxDivY = UINT_MAX / y;

        if (x <= maxDivY && maxDivY != UINT_MAX) {
            return (maxDivY + 1, y);
        }

        return (x, y);
    }

    function isMulOverflows(uint256 x, uint256 y) public pure returns (bool) {
        (uint256 overflowX, uint256 overflowY) = uFindMulOverflow(x, y);

        if (x == overflowX && y == overflowY) {
            return true;
        }

        return false;
    }

    function uFindDivisionWithoutRemainder(uint256 x, uint256 y, uint256 denominator) public pure returns (uint256) {
        if ((x * y) % denominator != 0) {
            return x / denominator * denominator;
        }
        return x;
    }

    function uFindDivisionWithRemainder(uint256 x, uint256 y, uint256 denominator)
        public
        pure
        returns (uint256, uint256, uint256)
    {
        if (denominator == 1) {
            denominator = 2;
        }

        if ((x * y) % denominator == 0) {
            if (x % denominator == 0 && y % denominator == 0) {
                x = x == UINT_MAX ? x - 1 : x + 1;
                y = y == UINT_MAX ? y - 1 : y + 1;

                if (isMulOverflows(x, y)) {
                    x = x - 2;
                    y = y - 2;
                }

                return (x, y, denominator);
            }

            if (x % denominator == 0) {
                x = x == UINT_MAX ? x - 1 : x + 1;

                if (isMulOverflows(x, y)) {
                    x = x - 2;
                }

                return (x, y, denominator);
            }

            if (y % denominator == 0) {
                y = y == UINT_MAX ? y - 1 : y + 1;

                if (isMulOverflows(x, y)) {
                    y = y - 2;
                }

                return (x, y, denominator);
            }

            if (x > 1) {
                x = x - 1;
            } else {
                y = y - 1;
            }
            return (x, y, denominator);
        }

        return (x, y, denominator);
    }

    function uFilterInputs(uint256 x, uint256 y, uint256 denominator) public pure returns (uint256, uint256, uint256) {
        x = uHandleZero(x);
        y = uHandleZero(y);
        denominator = uHandleZero(denominator);
        x = uEliminateMulOverflow(x, y);

        return (x, y, denominator);
    }
}
