// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../StateTransition.sol';
import '../Constants.sol';
import '../borrowVault/TotalAssets.sol';
import '../Lending.sol';
import '../math/DepositWithdraw.sol';
import '../math/NextStep.sol';
import './MaxDepositCollateral.sol';
import '../ERC4626Events.sol';
import '../MaxGrowthFee.sol';

abstract contract DepositCollateral is MaxDepositCollateral, StateTransition, Lending, ERC4626Events  {

    using uMulDiv for uint256;
    
    error ExceedsMaxDepositCollateral(address receiver, uint256 collateralAssets, uint256 max);

    function depositCollateral(uint256 collateralAssets, address receiver) external isFunctionAllowed nonReentrant returns (uint256 shares) {
        uint256 max = maxDepositCollateral(address(receiver));
        require(collateralAssets <= max, ExceedsMaxDepositCollateral(receiver, collateralAssets, max));

        ConvertedAssets memory convertedAssets = recoverConvertedAssets();
        Prices memory prices = getPrices();
        uint256 supplyAfterFee = previewSupplyAfterFee();
        (
            int256 signedSharesInUnderlying,
            DeltaFuture memory deltaFuture
        ) = DepositWithdraw.calculateDepositWithdraw(int256(collateralAssets), false, convertedAssets, prices, targetLTV);

        if (signedSharesInUnderlying < 0) {
            return 0;
        } else {
            uint256 sharesInAssets = uint256(signedSharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPriceCollateralOracle());
            shares = sharesInAssets.mulDivDown(supplyAfterFee, totalAssets());
        }

        // TODO: double check that Token should be transfered from msg.sender or from receiver
        collateralToken.transferFrom(msg.sender, address(this), collateralAssets);
        
        applyMaxGrowthFee(supplyAfterFee);

        _mintProtocolRewards(deltaFuture, prices, supplyAfterFee);

        supply(collateralAssets);

        NextState memory nextState = NextStep.calculateNextStep(convertedAssets, deltaFuture, block.number);

        applyStateTransition(nextState);

        emit DepositCollateral(msg.sender, receiver, collateralAssets, shares);

        _mint(receiver, shares);

        return shares;
    }
}
