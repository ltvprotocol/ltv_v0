// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/modifiers/WhitelistModifier.sol";
import "src/modifiers/FunctionStopperModifier.sol";
import "../events/IERC20Events.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "src/errors/IAdministrationErrors.sol";

abstract contract ERC20 is WhitelistModifier, FunctionStopperModifier, ReentrancyGuardUpgradeable, IERC20Events {
    function _mint(address to, uint256 amount) internal isReceiverWhitelisted(to) {
        require(!isDepositDisabled, DepositIsDisabled());
        balanceOf[to] += amount;
        baseTotalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(!isWithdrawDisabled, WithdrawIsDisabled());
        balanceOf[from] -= amount;
        baseTotalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}
