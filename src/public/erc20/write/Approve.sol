// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20Events} from "src/events/IERC20Events.sol";
import {IERC20Errors} from "src/errors/IERC20Errors.sol";
import {WhitelistModifier} from "src/modifiers/WhitelistModifier.sol";
import {FunctionStopperModifier} from "src/modifiers/FunctionStopperModifier.sol";
import {ERC20} from "src/state_transition/ERC20.sol";

/**
 * @title Approve
 * @notice This contract contains approve public function implementation.
 */
abstract contract Approve is
    WhitelistModifier,
    FunctionStopperModifier,
    ReentrancyGuardUpgradeable,
    IERC20Events,
    IERC20Errors,
    ERC20
{
    /**
     * @dev see ITLV.approve
     */
    function approve(address spender, uint256 amount) external isFunctionAllowed nonReentrant returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}
