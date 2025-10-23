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
 * @title Transfer
 * @notice This contract contains transfer public function implementation.
 */
abstract contract Transfer is
    WhitelistModifier,
    FunctionStopperModifier,
    ReentrancyGuardUpgradeable,
    IERC20Events,
    IERC20Errors,
    ERC20
{
    /**
     * @dev see ITLV.transfer
     */
    function transfer(address recipient, uint256 amount)
        external
        isFunctionAllowed
        isReceiverWhitelisted(recipient)
        nonReentrant
        returns (bool)
    {
        require(recipient != address(0), ERC20TransferToZeroAddress());
        require(balanceOf[msg.sender] >= amount, ERC20InsufficientBalance(msg.sender, balanceOf[msg.sender], amount));
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
}
