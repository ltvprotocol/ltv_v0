// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../states/LTVState.sol";
import "src/errors/IAdministrationErrors.sol";

abstract contract WhitelistModifier is LTVState, IAdministrationErrors {
    modifier isReceiverWhitelisted(address to) {
        _isReceiverWhitelisted(to);
        _;
    }

    function _isReceiverWhitelisted(address receiver) private view {
        require(
            !isWhitelistActivated || receiver == feeCollector || whitelistRegistry.isAddressWhitelisted(receiver),
            ReceiverNotWhitelisted(receiver)
        );
    }
}
