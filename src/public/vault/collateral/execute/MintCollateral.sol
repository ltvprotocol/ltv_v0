// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../max/MaxMintCollateral.sol";
import "../../../../state_transition/VaultStateTransition.sol";
import "../../../../state_transition/ERC20.sol";
import "../../../../state_transition/ApplyMaxGrowthFee.sol";
import "../../../../state_transition/MintProtocolRewards.sol";
import "../../../../state_transition/Lending.sol";
import "src/events/IERC4626Events.sol";
import "src/errors/IVaultErrors.sol";
import "../preview/PreviewMintCollateral.sol";
import "../../../../math/NextStep.sol";
import "src/state_reader/vault/MaxDepositMintCollateralVaultStateReader.sol";

abstract contract MintCollateral is
    MaxDepositMintCollateralVaultStateReader,
    MaxMintCollateral,
    ApplyMaxGrowthFee,
    MintProtocolRewards,
    Lending,
    VaultStateTransition,
    IERC4626Events,
    IVaultErrors
{
    using uMulDiv for uint256;

    function mintCollateral(uint256 shares, address receiver)
        external
        isFunctionAllowed
        nonReentrant
        returns (uint256)
    {
        MaxDepositMintCollateralVaultState memory state = maxDepositMintCollateralVaultState();
        MaxDepositMintCollateralVaultData memory data =
            maxDepositMintCollateralVaultStateToMaxDepositMintCollateralVaultData(state);
        uint256 max = _maxMintCollateral(data);
        require(shares <= max, ExceedsMaxMintCollateral(receiver, shares, max));

        (uint256 assets, DeltaFuture memory deltaFuture) =
            _previewMintCollateral(shares, data.previewCollateralVaultData);

        if (assets == 0) {
            return 0;
        }

        collateralToken.transferFrom(msg.sender, address(this), assets);

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

        supply(assets);

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
                borrowPrice: state.previewDepositVaultState.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
                collateralPrice: data.previewCollateralVaultData.collateralPrice
            })
        );

        emit Deposit(msg.sender, receiver, assets, shares);

        _mint(receiver, shares);

        return assets;
    }
}
