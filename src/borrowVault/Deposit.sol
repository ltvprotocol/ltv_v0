// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../State.sol';
import '../StateTransition.sol';
import '../Constants.sol';
import '../Structs.sol';
import './TotalAssets.sol';
import '../ERC20.sol';
import '../Cases.sol';
import '../Lending.sol';
import '../math/DepositWithdrawBorrow.sol';
import '../math/NextStep.sol';

abstract contract Deposit is State, StateTransition, TotalAssets, ERC20, DepositWithdrawBorrow, Lending, NextStep {

    using uMulDiv for uint256;

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        (
            int256 signedSharesInUnderlying,
            DeltaFuture memory deltaFuture
        ) = calculateDepositWithdrawBorrow(-1 * int256(assets));

        if (signedSharesInUnderlying < 0) {
            return 0;
        } else {
            uint256 sharesInAssets = uint256(signedSharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
            shares = sharesInAssets.mulDivDown(totalSupply(), totalAssets());
        }

        // TODO: double check that Token should be transfered from msg.sender or from receiver
        borrowToken.transferFrom(msg.sender, address(this), assets);

        repay(assets);

        // TODO: fix this - return from calculateDepositWithdrawBorrow
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        NextState memory nextState = calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        _mint(receiver, shares);

        return shares;
    }
}
