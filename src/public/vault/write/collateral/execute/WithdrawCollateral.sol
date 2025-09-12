// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC4626Events} from "src/events/IERC4626Events.sol";
import {IVaultErrors} from "src/errors/IVaultErrors.sol";
import {NextState} from "src/structs/state_transition/NextState.sol";
import {NextStateData} from "src/structs/state_transition/NextStateData.sol";
import {NextStepData} from "src/structs/state_transition/NextStepData.sol";
import {MaxWithdrawRedeemCollateralVaultData} from "src/structs/data/vault/max/MaxWithdrawRedeemCollateralVaultData.sol";
import {MaxWithdrawRedeemCollateralVaultState} from
    "src/structs/state/vault/max/MaxWithdrawRedeemCollateralVaultState.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {MintProtocolRewardsData} from "src/structs/data/vault/common/MintProtocolRewardsData.sol";
import {VaultStateTransition} from "src/state_transition/VaultStateTransition.sol";
import {ApplyMaxGrowthFee} from "src/state_transition/ApplyMaxGrowthFee.sol";
import {MintProtocolRewards} from "src/state_transition/MintProtocolRewards.sol";
import {Lending} from "src/state_transition/Lending.sol";
import {TransferFromProtocol} from "src/state_transition/TransferFromProtocol.sol";
import {MaxWithdrawRedeemCollateralVaultStateReader} from
    "src/state_reader/vault/MaxWithdrawRedeemCollateralVaultStateReader.sol";
import {MaxWithdrawCollateral} from "src/public/vault/read/collateral/max/MaxWithdrawCollateral.sol";
import {NextStep} from "src/math/libraries/NextStep.sol";
import {CommonMath} from "src/math/libraries/CommonMath.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title WithdrawCollateral
 * @notice This contract contains withdraw collateral function implementation.
 */
abstract contract WithdrawCollateral is
    MaxWithdrawRedeemCollateralVaultStateReader,
    MaxWithdrawCollateral,
    ApplyMaxGrowthFee,
    MintProtocolRewards,
    Lending,
    VaultStateTransition,
    TransferFromProtocol,
    IERC4626Events,
    IVaultErrors
{
    using UMulDiv for uint256;

    /**
     * @dev see ILTV.withdrawCollateral
     */
    function withdrawCollateral(uint256 assets, address receiver, address owner)
        external
        isFunctionAllowed
        nonReentrant
        returns (uint256)
    {
        MaxWithdrawRedeemCollateralVaultState memory state = maxWithdrawRedeemCollateralVaultState(owner);
        MaxWithdrawRedeemCollateralVaultData memory data =
            maxWithdrawRedeemCollateralVaultStateToMaxWithdrawRedeemCollateralVaultData(state);
        uint256 max = _maxWithdrawCollateral(data);
        require(assets <= max, ExceedsMaxWithdrawCollateral(owner, assets, max));

        (uint256 sharesOut, DeltaFuture memory deltaFuture) =
            _previewWithdrawCollateral(assets, data.previewCollateralVaultData);

        if (sharesOut == 0) {
            return 0;
        }

        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, sharesOut);
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
                assetPrice: data.previewCollateralVaultData.collateralPrice,
                assetTokenDecimals: data.previewCollateralVaultData.collateralTokenDecimals
            })
        );

        _burn(owner, sharesOut);

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
                collateralPrice: data.previewCollateralVaultData.collateralPrice,
                borrowTokenDecimals: state
                    .previewWithdrawVaultState
                    .maxGrowthFeeState
                    .commonTotalAssetsState
                    .borrowTokenDecimals,
                collateralTokenDecimals: data.previewCollateralVaultData.collateralTokenDecimals
            })
        );

        withdraw(assets);

        transferCollateralToken(receiver, assets);

        emit WithdrawCollateral(msg.sender, receiver, owner, assets, sharesOut);

        return sharesOut;
    }
}
