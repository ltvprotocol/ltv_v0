// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {EuclidianMod} from "../utils/math/EuclidianMod.sol";

contract SignedHelpers is EuclidianMod {
    function sHandleZero(int256 num) public pure returns(int256) {
        return num = num == int256(0) ? int256(1) : num;
    }

    // need to fix but works with hardcoded values
    function sEliminateMulOverflow(int256 x, int256 y) public pure returns(int256, int256) {
        y = y == -1 ? int256(1) : y;

        int256 max = type(int256).max;

        // one time expression that should be removed in the future
        if(x == max || y == max) {
            return (1, 5);
        }

        int256 maxDivY = max / y;

        if(x > 0 && y > 0 && x > maxDivY) {
            return (1, 5);
        }

        if(x < 0 && y < 0 && x < maxDivY) {
            return (1, 5);
        }

        int256 min = type(int256).min;

        // one time expression that should be removed in the future
        if(x == min || y == min) {
            return (1, 5);
        }

        int256 minDivY = min / y;

        if(x > 0 && y < 0 && x > minDivY) {
            return (1, 5);
        }

        if(x < 0 && y > 0 && x < minDivY) {
            return (1, 5);
        }

        return (x, y);
    }
    
    function sFindMulOverflow(int256 x, int256 y) public pure returns(int256, int256) {
        y = y == -1 ? int256(1) : y;
        x = x == -1 ? int256(1) : x;

        int256 max = type(int256).max;
        int256 maxDivY = max / y;

        if(x > 0 && y > 0 && x <= maxDivY) {
            return (max, 2);
        }

        if(x < 0 && y < 0 && x >= maxDivY) {
            return (max, 2);
        }

        int256 min = type(int256).min;
        int256 minDivY = min / y;

        if(x > 0 && y < 0 && x <= minDivY) {
            return (min, -1);
        }

        if(x < 0 && y > 0 && x >= minDivY) {
            return (min, -1);
        }

        return (x, y);
    }

    function sFindDivisionWithoutRemainder(int256 x, int256 y, int256 denominator) public pure returns(int256) {
        if (x * y % denominator != 0) {
            return x / denominator * denominator;
        }
        return x;
    }

    // need to fix but works with hardcoded values
    function sFindDivisionWithRemainder(int256 x, int256 y, int256 denominator) public pure returns(int256, int256, int256) {
        if(denominator == 1) {
            denominator = 2;
        }

        // need to think how to change or how to explain denominaotr sign check here
        if(x*y%denominator == 0) {
            if(denominator < 0) {
                return (3, 2, -4);
            }

            return (3, 2, 4);
        }
        
        if(x % denominator == 0 && y % denominator == 0) {
            if(denominator < 0) {
                return (3, 2, -4);
            }

            return (3, 2, 4);
        }

        if(x % denominator == 0) {
            if(denominator < 0) {
                return (3, 2, -4);
            }

            return (3, 2, 4);
        }

        if(y % denominator == 0)  {
            if(denominator < 0) {
                return (3, 2, -4);
            }

            return (3, 2, 4);
        }

        int256 remainder = sEuclidianMod(x*y, denominator);
        // x*y-remainder > min
        // x*y > min + remainder - overflow not happens
        if(x*y < type(int256).min + remainder) {
            if(denominator < 0) {
                return (3, 2, -4);
            }

            return (3, 2, 4);
        }
        
        return (x, y, denominator);
    }

    function toPositive(int256 num) public pure returns(int256) {
        if(num == 0) return 1;
        if(num == type(int256).min) return type(int256).max;

        num = num < 0 ? -num : num;
        return num;
    }

    function toNegative(int256 num) public pure returns(int256) {
        if(num == 0) return -1;

        num = num > 0 ? -num : num;
        return num;
    }

    function sFilterInputs(int256 x, int256 y, int256 denominator) public pure returns(int256, int256, int256) {
        x = sHandleZero(x);
        y = sHandleZero(y);
        denominator = sHandleZero(denominator);
        (x, y) = sEliminateMulOverflow(x, y);

        return (x, y, denominator);
    }
}
