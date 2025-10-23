// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IModules} from "../interfaces/IModules.sol";

/**
 * @title FacadeState
 * @notice contract contains state of modules address that are used in the facade
 */
abstract contract FacadeImplementationState {
    IModules public immutable MODULES;
}
