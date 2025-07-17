// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title RateMath
 * @dev Library for calculating compound interest rates and growth factors
 *
 * This library provides mathematical functions for calculating how amounts
 * grow over time when subject to compound interest. It's used by both the
 * DynamicOracle (for price increases) and DynamicLending (for debt increases).
 *
 * The library uses a Taylor series approximation to calculate compound growth
 * efficiently in Solidity, avoiding expensive exponential operations.
 *
 * Key features:
 * - Handles compound interest calculations up to cubic terms
 * - Uses 1e18 precision for high accuracy
 * - Supports both positive and negative growth rates
 */
library RateMath {
    /**
     * @dev Calculates the cumulative growth factor for a given rate and time period
     *
     * This function uses a Taylor series approximation to calculate compound growth:
     * (1 + r)^n ≈ 1 + nr + n(n-1)r²/2! + n(n-1)(n-2)r³/3!
     *
     * Where:
     * - r is the rate per block (in 1e18 precision)
     * - n is the number of blocks elapsed
     *
     * The function handles special cases for efficiency:
     * - 0 blocks: returns 1e18 (no growth)
     * - 1 block: returns the rate directly
     * - Multiple blocks: uses the full Taylor series approximation
     *
     * @param ratePerBlock The growth rate per block in 1e18 precision
     * @param blocksElapsed The number of blocks over which to calculate growth
     * @return The cumulative growth factor in 1e18 precision
     */
    function calculateRatePerBlock(uint256 ratePerBlock, uint256 blocksElapsed) internal pure returns (uint256) {
        // Special case: no time elapsed, no growth
        if (blocksElapsed == 0) {
            return 10 ** 18;
        }

        // Special case: one block elapsed, return rate directly
        if (blocksElapsed == 1) {
            return ratePerBlock;
        }

        // Calculate the increase per block (rate - 1e18)
        uint256 increasePerBlock = ratePerBlock - 10 ** 18;

        // Calculate squared term for quadratic approximation
        uint256 increasePerBlockSquared = increasePerBlock * increasePerBlock / 10 ** 18;

        // Calculate cubed term for cubic approximation
        uint256 increasePerBlockCubed = increasePerBlock * increasePerBlockSquared / 10 ** 18;

        // Apply Taylor series approximation:
        // 1 + nr + n(n-1)r²/2! + n(n-1)(n-2)r³/3!
        return 10 ** 18 + increasePerBlock * blocksElapsed
            + increasePerBlockSquared * blocksElapsed * (blocksElapsed - 1) / 2
            + increasePerBlockCubed * blocksElapsed * (blocksElapsed - 1) * (blocksElapsed - 2) / 6;
    }
}
