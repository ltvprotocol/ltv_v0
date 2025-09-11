// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "src/states/LTVState.sol";

/**
 * @title AssetCollateral
 * @notice This contract implements the assetCollateral() function for ERC4626 compatibility.
 * It returns the address of the collateral token, which is the underlying asset for the collateral vault.
 */
abstract contract AssetCollateral is LTVState {
    /**
     * @notice Returns the address of the underlying collateral asset managed by the vault.
     * @dev For ERC4626 compatibility, this should return the address of the token that can be deposited/withdrawn as collateral.
     * In the LTV protocol, the collateral vault manages the collateral token.
     * @return The address of the collateral token
     */
    function assetCollateral() external view returns (address) {
        return address(collateralToken);
    }
}
