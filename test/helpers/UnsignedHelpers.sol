// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

contract UnsignedHelpers {
    function uHandleZero(uint256 num) public pure returns(uint256) {
        return num = num == 0 ? 1 : num;
    }

    function uEliminateMulOverflow(uint256 x, uint256 y) public pure returns(uint256) {
        uint256 max = type(uint256).max;

        if (x > max / y) {
            return max / y - 1;
        }

        return x;
    }

    function uFindMulOverflow(uint256 x, uint256 y) public pure returns(uint256, uint256) {
        uint256 max = type(uint256).max;
        uint256 maxDivY = max / y;

        if (x <= maxDivY) {
            return (max, 2);
        }

        return (x, y);
    }

    function uFindDivisionWithoutRemainder(uint256 x, uint256 y, uint256 denominator) public pure returns(uint256) {
        if (x * y % denominator != 0) {
            return x / denominator * denominator;
        }
        return x;
    }

    // need to fix but works with hardcoded values
    function uFindDivisionWithRemainder(uint256 x, uint256 y, uint256 denominator) public pure returns(uint256, uint256, uint256) {
        if(denominator == 1) {
            denominator = 2;
        }

        if(x*y%denominator == 0) {
            return (3, 2, 4);
        }
        
        if(x % denominator == 0 && y % denominator == 0) {
            return (3, 2, 4);
        }

        if(x % denominator == 0) {
            return (3, 2, 4);
        }

        if(y % denominator == 0)  {
            return (3, 2, 4);
        }
        
        return (x, y, denominator);
    }

    function uFilterInputs(uint256 x, uint256 y, uint256 denominator) public pure returns(uint256, uint256, uint256) {
        x = uHandleZero(x);
        y = uHandleZero(y);
        denominator = uHandleZero(denominator);
        x = uEliminateMulOverflow(x, y);

        return (x, y, denominator);
    }
}
