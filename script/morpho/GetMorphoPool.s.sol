// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

library GetMorphoPool {
    function getMorphoPool() internal view returns (address) {
        if (block.chainid == 1) {
            return 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
        } else if (block.chainid == 11155111) {
            return 0xd011EE229E7459ba1ddd22631eF7bF528d424A14;
        } else {
            revert("Unsupported chain");
        }
    }
}
