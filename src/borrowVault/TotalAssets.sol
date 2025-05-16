// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import '../utils/MulDiv.sol';

abstract contract TotalAssets is State {

    using uMulDiv for uint256;
    function totalAssets() external view returns (uint256) {
        // default behavior - don't overestimate our assets
        return _totalAssets(false);
    }

    function _totalAssets(bool isDeposit) internal view override returns(uint256) {
        ConvertedAssets memory convertedAssets = recoverConvertedAssets(isDeposit);
        // Add 1 to avoid vault attack
        // in case of deposit need to overestimate our assets
        return uint256(convertedAssets.collateral - convertedAssets.borrow).mulDiv(Constants.ORACLE_DIVIDER, getPriceBorrowOracle(), isDeposit) + 1;
    }

}