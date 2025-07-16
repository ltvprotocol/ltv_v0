// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

library RateMath {
    uint256 public constant BLOCKS_PER_DAY = 7200;

    function calculateRatePerBlock(uint256 ratePerBlock, uint256 blocksElapsed) internal pure returns (uint256) {
        if (blocksElapsed == 0) {
            return 10 ** 18;
        }

        if (blocksElapsed == 1) {
            return ratePerBlock;
        }

        uint256 increasePerBlock = ratePerBlock - 10 ** 18;
        uint256 increasePerBlockSquared = increasePerBlock * increasePerBlock / 10 ** 18;
        uint256 increasePerBlockCubed = increasePerBlock * increasePerBlockSquared / 10 ** 18;

        return 10 ** 18 + increasePerBlock * blocksElapsed
            + increasePerBlockSquared * blocksElapsed * (blocksElapsed - 1) / 2
            + increasePerBlockCubed * blocksElapsed * (blocksElapsed - 1) * (blocksElapsed - 2) / 6;
    }
}
