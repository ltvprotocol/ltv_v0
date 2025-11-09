// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC4626Events} from "../../../../../events/IERC4626Events.sol";
import {IVaultErrors} from "../../../../../errors/IVaultErrors.sol";
import {NextState} from "../../../../../structs/state_transition/NextState.sol";
import {NextStateData} from "../../../../../structs/state_transition/NextStateData.sol";
import {NextStepData} from "../../../../../structs/state_transition/NextStepData.sol";
import {MaxWithdrawRedeemCollateralVaultData} from "../../../../../structs/data/vault/max/MaxWithdrawRedeemCollateralVaultData.sol";
import {MaxWithdrawRedeemCollateralVaultState} from
    "../../../../../structs/state/vault/max/MaxWithdrawRedeemCollateralVaultState.sol";
import {DeltaFuture} from "../../../../../structs/state_transition/DeltaFuture.sol";
import {MintProtocolRewardsData} from "../../../../../structs/data/vault/common/MintProtocolRewardsData.sol";
import {VaultStateTransition} from "../../../../../state_transition/VaultStateTransition.sol";
import {ApplyMaxGrowthFee} from "../../../../../state_transition/ApplyMaxGrowthFee.sol";
import {MintProtocolRewards} from "../../../../../state_transition/MintProtocolRewards.sol";
import {Lending} from "../../../../../state_transition/Lending.sol";
import {TransferFromProtocol} from "../../../../../state_transition/TransferFromProtocol.sol";
import {MaxWithdrawRedeemCollateralVaultStateReader} from
    "../../../../../state_reader/vault/MaxWithdrawRedeemCollateralVaultStateReader.sol";
import {MaxRedeemCollateral} from "../../../read/collateral/max/MaxRedeemCollateral.sol";
import {NextStep} from "../../../../../math/libraries/NextStep.sol";
import {CommonMath} from "../../../../../math/libraries/CommonMath.sol";
import {UMulDiv} from "../../../../../math/libraries/MulDiv.sol";

/**
 * @title RedeemCollateral
 * @notice This contract contains redeem collateral function implementation.
 */
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
    using UMulDiv for uint256;

    /**
     * @dev see ILTV.redeemCollateral
     */
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

        (uint256 assetsOut, DeltaFuture memory deltaFuture) =
            _previewRedeemCollateral(shares, data.previewCollateralVaultData);

        if (assetsOut == 0) {
            return 0;
        }

        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, shares);
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
                auctionStep: CommonMath.calculateAuctionStep(startAuction, uint56(block.number), auctionDuration),
                cases: deltaFuture.cases
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

        withdraw(assetsOut);

        transferCollateralToken(receiver, assetsOut);

        emit WithdrawCollateral(msg.sender, receiver, owner, assetsOut, shares);

        return assetsOut;
    }
}
