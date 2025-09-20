// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20Events} from "../events/IERC20Events.sol";
import {IERC20Errors} from "../errors/IERC20Errors.sol";
import {WhitelistModifier} from "../modifiers/WhitelistModifier.sol";
import {FunctionStopperModifier} from "../modifiers/FunctionStopperModifier.sol";

/**
 * @title ERC20
 * @notice contract contains internal ERC20 functions, which are used to update erc20 state of
 * the vault
 */
abstract contract ERC20 is
    WhitelistModifier,
    FunctionStopperModifier,
    ReentrancyGuardUpgradeable,
    IERC20Events,
    IERC20Errors
{
    /**
     * @dev Burns specified amount of tokens from the provided address
     */
    function _burn(address from, uint256 amount) internal {
        require(!_isWithdrawDisabled(boolSlot), WithdrawIsDisabled());
        balanceOf[from] -= amount;
        baseTotalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    /**
     * @dev Reduces allowance of the spender
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance[owner][spender];
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                allowance[owner][spender] = currentAllowance - value;
            }
        }
    }

    /**
     * @dev Mints specified amount of tokens to the provided address.
     * Also checks if the receiver is whitelisted and if token minting is enabled.
     */
    function _mintToUser(address to, uint256 amount) internal isReceiverWhitelisted(to) {
        require(!_isDepositDisabled(boolSlot), DepositIsDisabled());
        _mint(to, amount);
    }

    /**
     * @dev Mints specified amount of tokens to the fee collector.
     * Omits all checks when called for the fee collector
     */
    function _mintToFeeCollector(uint256 amount) internal {
        _mint(feeCollector, amount);
    }

    /**
     * @dev Mints specified amount of tokens to the provided address
     */
    function _mint(address to, uint256 amount) private {
        balanceOf[to] += amount;
        baseTotalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
}
