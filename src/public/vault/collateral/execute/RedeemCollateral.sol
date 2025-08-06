// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../max/MaxRedeemCollateral.sol";
import "../../../../state_transition/VaultStateTransition.sol";
import "../../../../state_transition/ERC20.sol";
import "../../../../state_transition/ApplyMaxGrowthFee.sol";
import "../../../../state_transition/MintProtocolRewards.sol";
import "../../../../state_transition/Lending.sol";
import "src/events/IERC4626Events.sol";
import "src/errors/IVaultErrors.sol";
import "../preview/PreviewRedeemCollateral.sol";
import "../../../../math/NextStep.sol";
import "src/state_reader/vault/MaxWithdrawRedeemCollateralVaultStateReader.sol";
import "../../../../state_transition/TransferFromProtocol.sol";

abstract contract RedeemCollateral is
    MaxWithdrawRedeemCollateralVaultStateReader,
    MaxRedeemCollateral,
    ApplyMaxGrowthFee,
    MintProtocolRewards,
    Lending,
    VaultStateTransition,
    TransferFromProtocol,
    IERC4626Events,
    IVaultErrors
{
    using uMulDiv for uint256;

    function redeemCollateral(uint256 shares, address receiver, address owner)
        external
        isFunctionAllowed
        nonReentrant
        returns (uint256)
    {
        MaxWithdrawRedeemCollateralVaultState memory state = maxWithdrawRedeemCollateralVaultState(owner);
        MaxWithdrawRedeemCollateralVaultData memory data =
            maxWithdrawRedeemCollateralVaultStateToMaxWithdrawRedeemCollateralVaultData(state);
        uint256 max = _maxRedeemCollateral(data);
        require(shares <= max, ExceedsMaxRedeemCollateral(owner, shares, max));

        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, shares);
        }

        (uint256 assets, DeltaFuture memory deltaFuture) =
            _previewRedeemCollateral(shares, data.previewCollateralVaultData);

        if (assets == 0) {
            return 0;
        }

        applyMaxGrowthFee(
            data.previewCollateralVaultData.supplyAfterFee, data.previewCollateralVaultData.withdrawTotalAssets
        );

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
                futureRewardBorrow: data.previewCollateralVaultData.userFutureRewardBorrow
                    + data.previewCollateralVaultData.protocolFutureRewardBorrow,
                futureRewardCollateral: data.previewCollateralVaultData.userFutureRewardCollateral
                    + data.previewCollateralVaultData.protocolFutureRewardCollateral,
                deltaFutureBorrow: deltaFuture.deltaFutureBorrow,
                deltaFutureCollateral: deltaFuture.deltaFutureCollateral,
                deltaFuturePaymentBorrow: deltaFuture.deltaFuturePaymentBorrow,
                deltaFuturePaymentCollateral: deltaFuture.deltaFuturePaymentCollateral,
                deltaUserFutureRewardBorrow: deltaFuture.deltaUserFutureRewardBorrow,
                deltaUserFutureRewardCollateral: deltaFuture.deltaUserFutureRewardCollateral,
                deltaProtocolFutureRewardBorrow: deltaFuture.deltaProtocolFutureRewardBorrow,
                deltaProtocolFutureRewardCollateral: deltaFuture.deltaProtocolFutureRewardCollateral,
                blockNumber: uint56(block.number),
                auctionStep: CommonMath.calculateAuctionStep(startAuction, uint56(block.number), auctionDuration)
            })
        );

        applyStateTransition(
            NextStateData({
                nextState: nextState,
                borrowPrice: state.previewWithdrawVaultState.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
                collateralPrice: data.previewCollateralVaultData.collateralPrice
            })
        );

        withdraw(assets);

        transferCollateralToken(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }
}
