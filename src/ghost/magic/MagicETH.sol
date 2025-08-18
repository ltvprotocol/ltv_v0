// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";

contract MagicETH is OwnableUpgradeable, ERC20Upgradeable {
    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
        //__Context_init();
        __ERC20_init("MagicETH", "MAE");
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
