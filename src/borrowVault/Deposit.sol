// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../StateTransition.sol';
import '../Constants.sol';
import '../Lending.sol';
import '../math/DepositWithdraw.sol';
import '../math/NextStep.sol';
import './MaxDeposit.sol';
import '../ERC4626Events.sol';

abstract contract Deposit is MaxDeposit, StateTransition, Lending, NextStep, ERC4626Events {

    using uMulDiv for uint256;
    
    error ExceedsMaxDeposit(address receiver, uint256 assets, uint256 max);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        uint256 max = maxDeposit(address(receiver));
        require(assets <= max, ExceedsMaxDeposit(receiver, assets, max));

        (
            int256 signedSharesInUnderlying,
            DeltaFuture memory deltaFuture
        ) = calculateDepositWithdraw(-1 * int256(assets), true);
        
        uint256 supplyAfterFee = previewSupplyAfterFee();
        if (signedSharesInUnderlying < 0) {
            return 0;
        } else {
            uint256 sharesInAssets = uint256(signedSharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().borrow);
            shares = sharesInAssets.mulDivDown(supplyAfterFee, totalAssets());
        }

        // TODO: double check that Token should be transfered from msg.sender or from receiver
        borrowToken.transferFrom(msg.sender, address(this), assets);

        applyMaxGrowthFee(supplyAfterFee);

        if (deltaFuture.deltaProtocolFutureRewardBorrow < 0) {
            _mint(FEE_COLLECTOR, underlyingToShares(uint256(-deltaFuture.deltaProtocolFutureRewardBorrow)));
        }

        if (deltaFuture.deltaProtocolFutureRewardCollateral > 0) {
            _mint(FEE_COLLECTOR, underlyingToShares(uint256(deltaFuture.deltaProtocolFutureRewardCollateral)));
        }

        repay(assets);

        // TODO: fix this - return from calculateDepositWithdraw
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        NextState memory nextState = calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        emit Deposit(msg.sender, receiver, assets, shares);

        _mint(receiver, shares);

        return shares;
    }
}
