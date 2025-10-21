// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {INonReentrantReadError} from "src/errors/INonReentrantReadError.sol";

/**
 * @title NonReentrantRead
 * @notice This contract contains a modifier for non-reentrant read functions.
 */
abstract contract NonReentrantRead is ReentrancyGuardUpgradeable, INonReentrantReadError {
    modifier nonReentrantRead() {
        _nonReentrantRead();
        _;
    }
    function _nonReentrantRead() internal view {
        require(!_reentrancyGuardEntered(), ReentrantReadDuringWriteCallError());
    }   
}
