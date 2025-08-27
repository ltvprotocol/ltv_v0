// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {ERC20Module} from "../../src/elements/ERC20Module.sol";
import {console} from "forge-std/console.sol";

contract DeployERC20Module is BaseScript {
    function deploy() internal override {
        ERC20Module erc20Module = new ERC20Module{salt: bytes32(0)}();
        console.log("ERC20Module deployed at: ", address(erc20Module));
    }

    function hashedCreationCode() internal pure override returns (bytes32) {
        return keccak256(type(ERC20Module).creationCode);
    }
}
