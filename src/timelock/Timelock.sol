// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "./TimelockCommon.sol";

contract Timelock is TimelockCommon {
    uint40 private _delay;

    constructor(address initialOwner, address initialGuardian, address initialPayloadsManager, uint40 __delay)
        WithPayloadsManager(initialOwner, initialGuardian, initialPayloadsManager)
    {
        _delay = __delay;
    }

    function delay() public view override returns (uint40) {
        return _delay;
    }

    function setDelay(uint40 __delay) external onlyOwner {
        _delay = __delay;
    }
}
