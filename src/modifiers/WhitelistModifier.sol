// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";
import {LTVState} from "src/states/LTVState.sol";
import {BoolReader} from "src/state_reader/BoolReader.sol";

abstract contract WhitelistModifier is LTVState, BoolReader, IAdministrationErrors {
    modifier isReceiverWhitelisted(address to) {
        _isReceiverWhitelisted(to);
        _;
    }

    function _isReceiverWhitelisted(address receiver) private view {
        require(
            !isWhitelistActivated() || receiver == feeCollector || whitelistRegistry.isAddressWhitelisted(receiver),
            ReceiverNotWhitelisted(receiver)
        );
    }
}
