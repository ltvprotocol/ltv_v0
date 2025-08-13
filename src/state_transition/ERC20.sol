// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/modifiers/WhitelistModifier.sol";
import "src/modifiers/FunctionStopperModifier.sol";
import "../events/IERC20Events.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "src/errors/IAdministrationErrors.sol";
import "src/errors/IERC20Errors.sol";
import "src/state_reader/BoolReader.sol";

abstract contract ERC20 is
    WhitelistModifier,
    FunctionStopperModifier,
    ReentrancyGuardUpgradeable,
    IERC20Events,
    IERC20Errors
{
    function _mint(address to, uint256 amount) internal isReceiverWhitelisted(to) {
        require(!isDepositDisabled(), DepositIsDisabled());
        balanceOf[to] += amount;
        baseTotalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(!isWithdrawDisabled(), WithdrawIsDisabled());
        balanceOf[from] -= amount;
        baseTotalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

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
}
