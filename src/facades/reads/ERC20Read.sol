// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/reads/IERC20Read.sol";
import "../../interfaces/IModules.sol";

import "../../states/readers/ModulesAddressStateReader.sol";
import "../../states/readers/ApplicationStateReader.sol";

abstract contract ERC20Read is ApplicationStateReader, ModulesAddressStateReader {

    function totalSupply() external view returns (uint256) {
        StateRepresentationStruct memory stateRepresentation = getStateRepresentation();
        address erc20ReadAddr = IModules(getModules()).erc20Read();
        return IERC20Read(erc20ReadAddr).totalSupply(stateRepresentation);
    }

}