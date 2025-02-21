// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../StateTransition.sol';
import '../Constants.sol';
import '../borrowVault/TotalAssets.sol';
import '../ERC20.sol';
import '../Lending.sol';
import '../math/DepositWithdraw.sol';
import '../math/NextStep.sol';
import './MaxDepositCollateral.sol';
import '../ERC4626Events.sol';

abstract contract DepositCollateral is MaxDepositCollateral, TotalAssets, DepositWithdraw, ERC20, StateTransition, Lending, NextStep, ERC4626Events  {

    using uMulDiv for uint256;
    
    error ExceedsMaxDepositCollateral(address receiver, uint256 collateralAssets, uint256 max);

    function depositCollateral(uint256 collateralAssets, address receiver) external returns (uint256 shares) {
        uint256 max = maxDepositCollateral(address(receiver));
        require(collateralAssets <= max, ExceedsMaxDepositCollateral(receiver, collateralAssets, max));

        (
            int256 signedSharesInUnderlying,
            DeltaFuture memory deltaFuture
        ) = calculateDepositWithdraw(int256(collateralAssets), false);

        if (signedSharesInUnderlying < 0) {
            return 0;
        } else {
            uint256 sharesInAssets = uint256(signedSharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPriceCollateralOracle());
            shares = sharesInAssets.mulDivDown(totalSupply(), totalAssets());
        }

        // TODO: double check that Token should be transfered from msg.sender or from receiver
        collateralToken.transferFrom(msg.sender, address(this), collateralAssets);

        if (deltaFuture.deltaProtocolFutureRewardBorrow < 0) {
            _mint(FEE_COLLECTOR, underlyingToShares(uint256(-deltaFuture.deltaProtocolFutureRewardBorrow)));
        }

        if (deltaFuture.deltaProtocolFutureRewardCollateral > 0) {
            _mint(FEE_COLLECTOR, underlyingToShares(uint256(deltaFuture.deltaProtocolFutureRewardCollateral)));
        }

        supply(collateralAssets);

        // TODO: fix this - return from calculateDepositWithdraw
        ConvertedAssets memory convertedAssets = recoverConvertedAssets();

        NextState memory nextState = calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        emit DepositCollateral(msg.sender, receiver, collateralAssets, shares);

        _mint(receiver, shares);

        return shares;
    }
}
