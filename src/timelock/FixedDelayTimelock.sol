// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "./TimelockCommon.sol";

contract FixedDelayTimelock is TimelockCommon {
    uint40 private immutable DELAY;

    constructor(
        address initialOwner,
        address initialGuardian,
        address initialPayloadsManager,
        uint40 _delay
    ) WithPayloadsManager(initialOwner, initialGuardian, initialPayloadsManager) {
        DELAY = _delay;
    }

    function delay() public view override returns (uint40) {
        return DELAY;
    }
}