// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './State.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

abstract contract ERC20 is State {
    using uMulDiv for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function __ERC20_init(string memory _name, string memory _symbol, uint8 _decimals) internal onlyInitializing {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address recipient, uint256 amount) external isFunctionAllowed nonReentrant returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external isFunctionAllowed nonReentrant returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external isFunctionAllowed nonReentrant returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal {
        balanceOf[to] += amount;
        baseTotalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;
        baseTotalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function _mintProtocolRewards(DeltaFuture memory deltaFuture, Prices memory prices, uint256 supply, bool isDeposit) internal {
        // in both cases rounding conflict between HODLer and fee collector. Resolve it in favor of HODLer
        if (deltaFuture.deltaProtocolFutureRewardBorrow < 0) {
            uint256 shares = uint256(-deltaFuture.deltaProtocolFutureRewardBorrow).mulDivDown(Constants.ORACLE_DIVIDER, prices.borrow).mulDivDown(
                supply,
                _totalAssets(isDeposit)
            );
            _mint(feeCollector, shares);
        } else if (deltaFuture.deltaProtocolFutureRewardCollateral > 0) {
            _mint(
                feeCollector,
                uint256(deltaFuture.deltaProtocolFutureRewardCollateral).mulDivDown(Constants.ORACLE_DIVIDER, prices.borrow).mulDivDown(
                    supply,
                    _totalAssets(isDeposit)
                )
            );
        }
    }
}
