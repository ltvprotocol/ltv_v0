// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../states/LTVState.sol';

contract Whitelist is LTVState {
    error ReceiverNotWhitelisted(address receiver);

    modifier isReceiverWhitelisted(address to) {
        _isReceiverWhitelisted(to);
        _;
    }

    function _isReceiverWhitelisted(address receiver) private view {
        require(!isWhitelistActivated || whitelistRegistry.isAddressWhitelisted(receiver), ReceiverNotWhitelisted(receiver));
    }
}
