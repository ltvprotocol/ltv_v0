// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20Events} from "src/events/IERC20Events.sol";
import {IERC20Errors} from "src/errors/IERC20Errors.sol";
import {WhitelistModifier} from "src/modifiers/WhitelistModifier.sol";
import {FunctionStopperModifier} from "src/modifiers/FunctionStopperModifier.sol";
import {ERC20} from "src/state_transition/ERC20.sol";

abstract contract TransferFrom is
    WhitelistModifier,
    FunctionStopperModifier,
    ReentrancyGuardUpgradeable,
    IERC20Events,
    IERC20Errors,
    ERC20
{
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        isFunctionAllowed
        isReceiverWhitelisted(recipient)
        nonReentrant
        returns (bool)
    {
        if (recipient == address(0)) {
            revert TransferToZeroAddress();
        }
        _spendAllowance(sender, msg.sender, amount);
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}
