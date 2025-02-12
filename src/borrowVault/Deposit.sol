// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../StateTransition.sol';
import '../Constants.sol';
import './TotalAssets.sol';
import '../ERC20.sol';
import '../Lending.sol';
import '../math/DepositWithdraw.sol';
import '../math/NextStep.sol';
import './MaxDeposit.sol';

abstract contract Deposit is MaxDeposit, TotalAssets, DepositWithdraw, ERC20, StateTransition, Lending, NextStep  {

    using uMulDiv for uint256;
    
    error ExceedsMaxDeposit(address receiver, uint256 assets, uint256 max);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        uint256 max = maxDeposit(address(receiver));
        require(assets <= max, ExceedsMaxDeposit(receiver, assets, max));

        (
            int256 signedSharesInUnderlying,
            DeltaFuture memory deltaFuture
        ) = calculateDepositWithdraw(-1 * int256(assets), true);

        if (signedSharesInUnderlying < 0) {
            return 0;
        } else {
            uint256 sharesInAssets = uint256(signedSharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
            shares = sharesInAssets.mulDivDown(totalSupply(), totalAssets());
        }

        // TODO: double check that Token should be transfered from msg.sender or from receiver
        borrowToken.transferFrom(msg.sender, address(this), assets);

        repay(assets);

        // TODO: fix this - return from calculateDepositWithdraw
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        NextState memory nextState = calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        _mint(receiver, shares);

        return shares;
    }
}
