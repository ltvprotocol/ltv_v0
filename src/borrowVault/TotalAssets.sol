// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";
import '../utils/MulDiv.sol';

abstract contract TotalAssets is State {

    using uMulDiv for uint256;
    function totalAssets() public view returns (uint256) {
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        // Add 1 to avoid vault attack
        return uint256(convertedAssets.collateral - convertedAssets.borrow).mulDivUp(Constants.ORACLE_DIVIDER, getPrices().borrow) + 1;
    }

    function underlyingToShares(uint256 underlying) internal view returns (uint256) {
        uint256 assets = underlying.mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
        uint256 shares = assets.mulDivDown(totalSupply(), totalAssets());
        return shares;
    }

}