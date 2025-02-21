// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../StateTransition.sol";
import "../Constants.sol";
import "../ERC20.sol";
import "../Lending.sol";
import "../math/NextStep.sol";
import './MaxWithdraw.sol';
import '../math/DepositWithdraw.sol';
import '../ERC4626Events.sol';

abstract contract Withdraw is MaxWithdraw, DepositWithdraw, ERC20, StateTransition, Lending, NextStep, ERC4626Events{

    using uMulDiv for uint256;
    
    error ExceedsMaxWithdraw(address owner, uint256 assets, uint256 max);

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {
        uint256 max = maxWithdraw(address(owner));
        require(assets <= max, ExceedsMaxWithdraw(owner, assets, max));

        (int256 sharesInUnderlying, DeltaFuture memory deltaFuture) = calculateDepositWithdraw(int256(assets), true);

        if (sharesInUnderlying > 0) {
            return 0;
        } else{
            uint256 sharesInAssets = uint256(-sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
            shares = sharesInAssets.mulDivDown(totalSupply(), totalAssets());
        }

        if (owner != receiver) {
            allowance[owner][receiver] -= shares;
        }

        if (deltaFuture.deltaProtocolFutureRewardBorrow < 0) {
            _mint(FEE_COLLECTOR, underlyingToShares(uint256(-deltaFuture.deltaProtocolFutureRewardBorrow)));
        }

        if (deltaFuture.deltaProtocolFutureRewardCollateral > 0) {
            _mint(FEE_COLLECTOR, underlyingToShares(uint256(deltaFuture.deltaProtocolFutureRewardCollateral)));
        }

        _burn(owner, shares);

        // TODO: fix this - return from calculateDepositWithdraw
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        NextState memory nextState = calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        borrow(assets);

        borrowToken.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }

}
