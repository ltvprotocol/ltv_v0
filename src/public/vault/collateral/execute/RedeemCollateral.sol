// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../max/MaxRedeemCollateral.sol';
import '../../../../state_transition/VaultStateTransition.sol';
import '../../../../state_transition/ERC20.sol';
import '../../../../state_transition/ApplyMaxGrowthFee.sol';
import '../../../../state_transition/MintProtocolRewards.sol';
import '../../../../state_transition/Lending.sol';
import '../../../../ERC4626Events.sol';
import '../preview/PreviewRedeemCollateral.sol';
import '../../../../math2/NextStep.sol';

abstract contract RedeemCollateral is MaxRedeemCollateral, ApplyMaxGrowthFee, MintProtocolRewards, Lending, VaultStateTransition, ERC4626Events {
    using uMulDiv for uint256;

    error ExceedsMaxRedeemCollateral(address owner, uint256 shares, uint256 max);

    function redeemCollateral(uint256 shares, address receiver, address owner) external isFunctionAllowed nonReentrant returns (uint256) {
        MaxWithdrawRedeemCollateralVaultState memory state = maxWithdrawRedeemCollateralVaultState(owner);
        MaxWithdrawRedeemCollateralVaultData memory data = maxWithdrawRedeemCollateralVaultStateToMaxWithdrawRedeemCollateralVaultData(state);
        uint256 max = _maxRedeemCollateral(data);
        require(shares <= max, ExceedsMaxRedeemCollateral(owner, shares, max));

        if (owner != receiver) {
            allowance[owner][receiver] -= shares;
        }

        (uint256 assets, DeltaFuture memory deltaFuture) = _previewRedeemCollateral(shares, data.previewCollateralVaultData);

        if (assets == 0) {
            return 0;
        }

        uint256 withdrawTotalAssets = _totalAssets(
            false,
            TotalAssetsData({
                collateral: data.previewCollateralVaultData.collateral,
                borrow: data.previewCollateralVaultData.borrow,
                borrowPrice: state.previewVaultState.maxGrowthFeeState.totalAssetsState.borrowPrice
            })
        );

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

        _burn(owner, shares);

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

        applyStateTransition(nextState);

        collateralToken.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }
}
