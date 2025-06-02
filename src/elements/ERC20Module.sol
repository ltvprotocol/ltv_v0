// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/public/erc20/ERC20WriteImpl.sol";
import "src/public/erc20/TotalSupply.sol";

contract ERC20Module is ERC20WriteImpl, TotalSupply {}
