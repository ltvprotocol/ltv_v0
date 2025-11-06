// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20Events} from "../../../events/IERC20Events.sol";
import {IERC20Errors} from "../../../errors/IERC20Errors.sol";
import {WhitelistModifier} from "../../../modifiers/WhitelistModifier.sol";
import {FunctionStopperModifier} from "../../../modifiers/FunctionStopperModifier.sol";
import {ERC20} from "../../../state_transition/ERC20.sol";

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
