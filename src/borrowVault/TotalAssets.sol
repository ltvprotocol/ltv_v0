// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import '../utils/MulDiv.sol';

abstract contract TotalAssets is State {

    using uMulDiv for uint256;
    function totalAssets() public view override returns (uint256) {
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        // Add 1 to avoid vault attack
        return uint256(convertedAssets.collateral - convertedAssets.borrow).mulDivUp(Constants.ORACLE_DIVIDER, getPriceBorrowOracle()) + 1;
    }

}
