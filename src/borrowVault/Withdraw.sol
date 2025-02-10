// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../StateTransition.sol";
import "../Constants.sol";
import "../ERC20.sol";
import "../Lending.sol";
import "../math/NextStep.sol";
import './MaxWithdraw.sol';

abstract contract Withdraw is MaxWithdraw, ERC20, StateTransition, Lending, NextStep{

    using uMulDiv for uint256;
    
    error ExceedsMaxWithdraw(address owner, uint256 assets, uint256 max);

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {
        uint256 max = maxWithdraw(address(owner));
        require(assets <= max, ExceedsMaxWithdraw(owner, assets, max));

        (int256 sharesInUnderlying, DeltaFuture memory deltaFuture) = calculateDepositWithdrawBorrow(int256(assets));

        if (sharesInUnderlying > 0) {
            return 0;
        } else{
            uint256 sharesInAssets = uint256(-sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
            shares = sharesInAssets.mulDivDown(totalSupply(), totalAssets());
        }

        if (owner != receiver) {
            allowance[owner][receiver] -= shares;
        }

        _burn(owner, shares);

        // TODO: fix this - return from calculateDepositWithdrawBorrow
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        NextState memory nextState = calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        borrow(assets);

        borrowToken.transfer(receiver, assets);

        return shares;
    }

}
