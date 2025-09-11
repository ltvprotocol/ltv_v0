// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTVState} from "src/states/LTVState.sol";

/**
 * @title Asset
 * @notice This contract implements the asset() function for ERC4626 compatibility.
 * It returns the address of the borrow token, which is the underlying asset for the borrow vault.
 */
abstract contract Asset is LTVState {
    /**
     * @notice Returns the address of the underlying asset managed by the vault.
     * @dev For ERC4626 compatibility, this should return the address of the token that can be deposited/withdrawn.
     * In the LTV protocol, the borrow vault manages the borrow token.
     * @return The address of the borrow token
     */
    function asset() external view returns (address) {
        return address(borrowToken);
    }
}
