// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../states/LTVState.sol';
import '../writes/CommonWrite.sol';
import 'src/structs/state/StateInitData.sol';

abstract contract InitializeWrite is LTVState, CommonWrite {
    function initialize(StateInitData memory initData) public {
        _delegate(modules.initializeWrite(), abi.encode(initData));
    }
}
