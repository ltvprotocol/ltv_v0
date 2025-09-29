// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Cases} from "src/structs/data/vault/common/Cases.sol";

/**
 * @title CasesOperator
 * @notice This library contains function to generate a specific case.
 */
library CasesOperator {
    function generateCase(uint8 ncase) internal pure returns (Cases memory) {
        return Cases({
            cmcb: (ncase == 0) ? 1 : 0,
            cmbc: (ncase == 1) ? 1 : 0,
            cecb: (ncase == 2) ? 1 : 0,
            cebc: (ncase == 3) ? 1 : 0,
            ceccb: (ncase == 4) ? 1 : 0,
            cecbc: (ncase == 5) ? 1 : 0,
            cna: (ncase == 6) ? 1 : 0,
            ncase: ncase
        });
    }
}
