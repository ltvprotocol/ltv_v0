// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IAdministrationErrors} from "../errors/IAdministrationErrors.sol";
import {LTVState} from "../states/LTVState.sol";
import {BoolReader} from "../math/abstracts/BoolReader.sol";

abstract contract WhitelistModifier is LTVState, BoolReader, IAdministrationErrors {
    modifier isReceiverWhitelisted(address to) {
        _isReceiverWhitelisted(to);
        _;
    }

    function _isReceiverWhitelisted(address receiver) private view {
        require(
            !_isWhitelistActivated(boolSlot) || receiver == feeCollector
                || whitelistRegistry.isAddressWhitelisted(receiver),
            ReceiverNotWhitelisted(receiver)
        );
    }
}
