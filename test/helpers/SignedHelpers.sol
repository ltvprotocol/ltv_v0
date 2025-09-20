// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {EuclidianMod} from "../utils/math/EuclidianMod.sol";

contract SignedHelpers is EuclidianMod {
    int256 constant INT_MAX = type(int256).max;
    int256 constant INT_MIN = type(int256).min;

    function sHandleZero(int256 num) public pure returns (int256) {
        return num = num == int256(0) ? int256(1) : num;
    }

    function sEliminateMulOverflow(int256 x, int256 y) public pure returns (int256, int256) {
        y = y == -1 ? int256(1) : y;

        int256 maxDivY = INT_MAX / y;

        if (x > 0 && y > 0 && x > maxDivY) {
            return (maxDivY - 1, y);
        }

        if (x < 0 && y < 0 && x < maxDivY) {
            return (maxDivY + 1, y);
        }

        int256 minDivY = INT_MIN / y;

        if (x > 0 && y < 0 && x > minDivY) {
            return (minDivY - 1, y);
        }

        if (x < 0 && y > 0 && x < minDivY) {
            return (minDivY + 1, y);
        }

        return (x, y);
    }

    function sEliminateDivOverflow(int256 x, int256 y, int256 denominator)
        public
        pure
        returns (int256, int256, int256)
    {
        int256 product = x * y;

        if (product == INT_MIN && denominator == -1) {
            return (x, y, 1);
        }

        return (x, y, denominator);
    }

    function sFindMulOverflow(int256 x, int256 y) public pure returns (int256, int256) {
        if ((x == INT_MIN && y == -1) || (x == -1 && y == INT_MIN)) {
            return (x, y);
        }

        y = y == -1 ? int256(1) : y;
        x = x == -1 ? int256(1) : x;

        if (x == 1 || y == 1) {
            return (2, INT_MAX);
        }

        int256 maxDivY = INT_MAX / y;

        if (x > 0 && y > 0 && x <= maxDivY) {
            return (maxDivY + 1, y);
        }

        if (x < 0 && y < 0 && x >= maxDivY) {
            return (maxDivY - 1, y);
        }

        int256 minDivY = INT_MIN / y;

        if (x > 0 && y < 0 && x <= minDivY) {
            return (minDivY + 1, y);
        }

        if (x < 0 && y > 0 && x >= minDivY) {
            return (minDivY - 1, y);
        }

        return (x, y);
    }

    function sFindDivisionWithoutRemainder(int256 x, int256 y, int256 denominator) public pure returns (int256) {
        if ((x * y) % denominator != 0) {
            // forge-lint: disable-next-line
            return (x / denominator) * denominator;
        }
        return x;
    }

    function isMulOverflows(int256 x, int256 y) public pure returns (bool) {
        (int256 overflowX, int256 overflowY) = sFindMulOverflow(x, y);

        if (x == overflowX && y == overflowY) {
            return true;
        }

        return false;
    }

    // probably not possible to rewrite without hardcoded values
    function eliminateProductSubRemainderOverflow(int256 x, int256 y, int256 denominator)
        public
        pure
        returns (int256, int256, int256)
    {
        int256 remainder = sEuclidianMod(x * y, denominator);
        // x*y-remainder > min
        // x*y > min + remainder - overflow not happens
        if (x * y < INT_MIN + remainder) {
            if (denominator < 0) {
                return (3, 2, -4);
            }

            return (3, 2, 4);
        }

        return (x, y, denominator);
    }

    function sFindDivisionWithRemainder(int256 x, int256 y, int256 denominator)
        public
        pure
        returns (int256, int256, int256)
    {
        if (denominator == 1 || (x * y == INT_MIN && denominator == -1) || denominator == -1) {
            denominator = denominator > 0 ? int256(2) : -2;
        }

        x = x == INT_MAX ? int256(1) : x;
        y = y == INT_MAX ? int256(1) : y;

        if ((x * y) % denominator == 0) {
            if (x % denominator == 0 && y % denominator == 0) {
                x = x == INT_MAX ? x - 1 : x + 1;
                y = y == INT_MAX ? y - 1 : y + 1;

                if (isMulOverflows(x, y)) {
                    x = x - 2;
                    y = y - 2;
                }

                (x, y, denominator) = eliminateProductSubRemainderOverflow(x, y, denominator);

                return (x, y, denominator);
            }

            if (x % denominator == 0) {
                x = x == INT_MAX ? x - 1 : x + 1;

                if (isMulOverflows(x, y)) {
                    x = x - 2;
                }

                (x, y, denominator) = eliminateProductSubRemainderOverflow(x, y, denominator);

                return (x, y, denominator);
            }

            if (y % denominator == 0) {
                y = y == INT_MAX ? y - 1 : y + 1;

                if (isMulOverflows(x, y)) {
                    y = y - 2;
                }

                (x, y, denominator) = eliminateProductSubRemainderOverflow(x, y, denominator);

                return (x, y, denominator);
            }

            if (x > 1) {
                x = x - 1;
            } else if (x < -1) {
                x = x + 1;
            } else if (y > 1) {
                y = y - 1;
            } else {
                y = y + 1;
            }

            (x, y, denominator) = eliminateProductSubRemainderOverflow(x, y, denominator);
            return (x, y, denominator);
        }

        (x, y, denominator) = eliminateProductSubRemainderOverflow(x, y, denominator);

        return (x, y, denominator);
    }

    function toPositive(int256 num) public pure returns (int256) {
        if (num == 0) return 1;
        if (num == INT_MIN) return INT_MAX;

        num = num < 0 ? -num : num;
        return num;
    }

    function toNegative(int256 num) public pure returns (int256) {
        if (num == 0) return -1;

        num = num > 0 ? -num : num;
        return num;
    }

    function sFilterInputs(int256 x, int256 y, int256 denominator) public pure returns (int256, int256, int256) {
        x = sHandleZero(x);
        y = sHandleZero(y);
        denominator = sHandleZero(denominator);
        (x, y) = sEliminateMulOverflow(x, y);

        return (x, y, denominator);
    }
}
