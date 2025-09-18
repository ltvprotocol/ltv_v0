// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IAdministrationErrors} from "../errors/IAdministrationErrors.sol";
import {LTVState} from "../states/LTVState.sol";
import {BoolReader} from "../math/abstracts/BoolReader.sol";

/**
 * @title WhitelistModifier
 * @notice This contract contains modifiers for the whitelist functionality of the LTV protocol.
 * It checks if the receiver is whitelisted.
 */
abstract contract WhitelistModifier is LTVState, BoolReader, IAdministrationErrors {
    /**
     * @dev modifier to check if the receiver is whitelisted
     */
    modifier isReceiverWhitelisted(address to) {
        _isReceiverWhitelisted(to);
        _;
    }

    /**
     * @dev checks if the receiver is whitelisted
     */
    function _isReceiverWhitelisted(address receiver) private view {
        require(
            !_isWhitelistActivated(boolSlot) || whitelistRegistry.isAddressWhitelisted(receiver),
            ReceiverNotWhitelisted(receiver)
        );
    }
}
