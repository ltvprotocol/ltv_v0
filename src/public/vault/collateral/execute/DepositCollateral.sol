// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../max/MaxDepositCollateral.sol';
import '../../../../state_transition/VaultStateTransition.sol';
import '../../../../state_transition/ERC20.sol';
import '../../../../state_transition/ApplyMaxGrowthFee.sol';
import '../../../../state_transition/MintProtocolRewards.sol';
import '../../../../state_transition/Lending.sol';
import '../../../../ERC4626Events.sol';
import '../preview/PreviewDepositCollateral.sol';
import '../../../../math2/NextStep.sol';

abstract contract DepositCollateral is MaxDepositCollateral, ApplyMaxGrowthFee, MintProtocolRewards, Lending, VaultStateTransition, ERC4626Events {
    using uMulDiv for uint256;

    error ExceedsMaxDepositCollateral(address receiver, uint256 assets, uint256 max);

    function depositCollateral(uint256 assets, address receiver) external isFunctionAllowed nonReentrant returns (uint256) {
        MaxDepositMintCollateralVaultState memory state = maxDepositMintCollateralVaultState();
        MaxDepositMintCollateralVaultData memory data = maxDepositMintCollateralVaultStateToMaxDepositMintCollateralVaultData(state);
        uint256 max = _maxDepositCollateral(data);
        require(assets <= max, ExceedsMaxDepositCollateral(receiver, assets, max));

        (uint256 shares, DeltaFuture memory deltaFuture) = _previewDepositCollateral(assets, data.previewCollateralVaultData);

        if (shares == 0) {
            return 0;
        }

        collateralToken.transferFrom(msg.sender, address(this), assets);

        uint256 withdrawTotalAssets = totalAssets(false, state.previewVaultState.maxGrowthFeeState.totalAssetsState);

        applyMaxGrowthFee(data.previewCollateralVaultData.supplyAfterFee, withdrawTotalAssets);

        _mintProtocolRewards(
            MintProtocolRewardsData({
                deltaProtocolFutureRewardBorrow: deltaFuture.deltaProtocolFutureRewardBorrow,
                deltaProtocolFutureRewardCollateral: deltaFuture.deltaProtocolFutureRewardCollateral,
                supply: data.previewCollateralVaultData.supplyAfterFee,
                totalAppropriateAssets: data.previewCollateralVaultData.totalAssetsCollateral,
                assetPrice: data.previewCollateralVaultData.collateralPrice
            })
        );

        supply(assets);

        NextState memory nextState = NextStep.calculateNextStep(
            NextStepData({
                futureBorrow: data.previewCollateralVaultData.futureBorrow,
                futureCollateral: data.previewCollateralVaultData.futureCollateral,
                futureRewardBorrow: data.previewCollateralVaultData.userFutureRewardBorrow +
                    data.previewCollateralVaultData.protocolFutureRewardBorrow,
                futureRewardCollateral: data.previewCollateralVaultData.userFutureRewardCollateral +
                    data.previewCollateralVaultData.protocolFutureRewardCollateral,
                deltaFutureBorrow: deltaFuture.deltaFutureBorrow,
                deltaFutureCollateral: deltaFuture.deltaFutureCollateral,
                deltaFuturePaymentBorrow: deltaFuture.deltaFuturePaymentBorrow,
                deltaFuturePaymentCollateral: deltaFuture.deltaFuturePaymentCollateral,
                deltaUserFutureRewardBorrow: deltaFuture.deltaUserFutureRewardBorrow,
                deltaUserFutureRewardCollateral: deltaFuture.deltaUserFutureRewardCollateral,
                deltaProtocolFutureRewardBorrow: deltaFuture.deltaProtocolFutureRewardBorrow,
                deltaProtocolFutureRewardCollateral: deltaFuture.deltaProtocolFutureRewardCollateral,
                blockNumber: block.number,
                auctionStep: CommonMath.calculateAuctionStep(startAuction, block.number)
            })
        );

        applyStateTransition(
            NextStateData({
                nextState: nextState,
                borrowPrice: state.previewVaultState.maxGrowthFeeState.totalAssetsState.borrowPrice,
                collateralPrice: data.previewCollateralVaultData.collateralPrice
            })
        );

        emit Deposit(msg.sender, receiver, assets, shares);

        _mint(receiver, shares);

        return shares;
    }
}
