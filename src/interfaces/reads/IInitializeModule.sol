// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../structs/state/StateInitData.sol";

interface IInitializeModule {
    function initialize(StateInitData memory initData) external;
}
