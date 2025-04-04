// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../StateTransition.sol';
import '../Constants.sol';
import '../ERC20.sol';
import '../Lending.sol';
import '../math/NextStep.sol';
import './MaxWithdraw.sol';
import '../math/DepositWithdraw.sol';
import '../ERC4626Events.sol';

abstract contract Withdraw is MaxWithdraw, StateTransition, Lending, ERC4626Events {
    using uMulDiv for uint256;

    error ExceedsMaxWithdraw(address owner, uint256 assets, uint256 max);

    function withdraw(uint256 assets, address receiver, address owner) external isFunctionAllowed nonReentrant returns (uint256) {
        uint256 max = maxWithdraw(address(owner));
        require(assets <= max, ExceedsMaxWithdraw(owner, assets, max));

        ConvertedAssets memory convertedAssets = recoverConvertedAssets(false);
        Prices memory prices = getPrices();
        (int256 sharesInUnderlying, DeltaFuture memory deltaFuture) = DepositWithdraw.calculateDepositWithdraw(
            int256(assets),
            true,
            convertedAssets,
            prices,
            targetLTV
        );

        uint256 supplyAfterFee = previewSupplyAfterFee();
        if (sharesInUnderlying > 0) {
            return 0;
        }

        // HODLer <=> withdrawer conflict, round in favor of HODLer, round up to burn more shares
        uint256 shares = uint256(-sharesInUnderlying).mulDivUp(Constants.ORACLE_DIVIDER, prices.borrow).mulDivUp(supplyAfterFee, _totalAssets(false));

        if (owner != receiver) {
            allowance[owner][receiver] -= shares;
        }

        applyMaxGrowthFee(supplyAfterFee);

        _mintProtocolRewards(deltaFuture, prices, supplyAfterFee, false);

        _burn(owner, shares);

        NextState memory nextState = NextStep.calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        borrow(assets);

        borrowToken.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }
}
