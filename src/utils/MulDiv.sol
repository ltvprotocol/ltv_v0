// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

library MulDiv {

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    function mulDivDown(
        uint256 factorA,
        uint256 factorB,
        uint256 denominator
    ) internal pure returns (uint256 result) {

        /// @solidity memory-safe-assembly
        assembly {
            if iszero(
                mul(
                    denominator,
                    iszero(
                        mul(
                            factorB,
                            gt(
                                factorA,
                                div(MAX_UINT256, factorB)
                            )
                        )
                    )
                )
            ) {
                revert(0, 0)
            }

            result := div(mul(factorA, factorB), denominator)
        }
    }
    
}