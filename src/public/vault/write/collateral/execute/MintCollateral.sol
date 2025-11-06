// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626Events} from "../../../../../events/IERC4626Events.sol";
import {IVaultErrors} from "../../../../../errors/IVaultErrors.sol";
import {NextState} from "../../../../../structs/state_transition/NextState.sol";
import {NextStateData} from "../../../../../structs/state_transition/NextStateData.sol";
import {NextStepData} from "../../../../../structs/state_transition/NextStepData.sol";
import {MaxDepositMintCollateralVaultData} from "../../../../../structs/data/vault/max/MaxDepositMintCollateralVaultData.sol";
import {MaxDepositMintCollateralVaultState} from "../../../../../structs/state/vault/max/MaxDepositMintCollateralVaultState.sol";
import {DeltaFuture} from "../../../../../structs/state_transition/DeltaFuture.sol";
import {MintProtocolRewardsData} from "../../../../../structs/data/vault/common/MintProtocolRewardsData.sol";
import {VaultStateTransition} from "../../../../../state_transition/VaultStateTransition.sol";
import {ApplyMaxGrowthFee} from "../../../../../state_transition/ApplyMaxGrowthFee.sol";
import {MintProtocolRewards} from "../../../../../state_transition/MintProtocolRewards.sol";
import {Lending} from "../../../../../state_transition/Lending.sol";
import {MaxDepositMintCollateralVaultStateReader} from
    "../../../../../state_reader/vault/MaxDepositMintCollateralVaultStateReader.sol";
import {MaxMintCollateral} from "../../../read/collateral/max/MaxMintCollateral.sol";
import {NextStep} from "../../../../../math/libraries/NextStep.sol";
import {CommonMath} from "../../../../../math/libraries/CommonMath.sol";
import {UMulDiv} from "../../../../../math/libraries/MulDiv.sol";

/**
 * @title MintCollateral
 * @notice This contract contains mint collateral function implementation.
 */
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
    using UMulDiv for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev see ILTV.mintCollateral
     */
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

        (uint256 assetsOut, DeltaFuture memory deltaFuture) =
            _previewMintCollateral(shares, data.previewCollateralVaultData);

        if (assetsOut == 0) {
            return 0;
        }

        collateralToken.safeTransferFrom(msg.sender, address(this), assetsOut);

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

        supply(assetsOut);

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
                borrowPrice: state.previewDepositVaultState.maxGrowthFeeState.commonTotalAssetsState.borrowPrice,
                collateralPrice: data.previewCollateralVaultData.collateralPrice,
                borrowTokenDecimals: state
                    .previewDepositVaultState
                    .maxGrowthFeeState
                    .commonTotalAssetsState
                    .borrowTokenDecimals,
                collateralTokenDecimals: data.previewCollateralVaultData.collateralTokenDecimals
            })
        );

        emit DepositCollateral(msg.sender, receiver, assetsOut, shares);

        _mintToUser(receiver, shares);

        return assetsOut;
    }
}
