// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../State.sol";
import "../Constants.sol";
import "../Structs.sol";

abstract contract TotalAssets is State {

    function totalAssets() public view returns (uint256) {
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        int256 signedTotalAssets = convertedAssets.collateral - convertedAssets.borrow;
        // Add 1 to avoid vault attack
        return uint256(signedTotalAssets) + 1;
    }

}