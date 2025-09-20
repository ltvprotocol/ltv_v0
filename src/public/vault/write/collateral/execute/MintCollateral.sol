// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626Events} from "src/events/IERC4626Events.sol";
import {IVaultErrors} from "src/errors/IVaultErrors.sol";
import {NextState} from "src/structs/state_transition/NextState.sol";
import {NextStateData} from "src/structs/state_transition/NextStateData.sol";
import {NextStepData} from "src/structs/state_transition/NextStepData.sol";
import {MaxDepositMintCollateralVaultData} from "src/structs/data/vault/max/MaxDepositMintCollateralVaultData.sol";
import {MaxDepositMintCollateralVaultState} from "src/structs/state/vault/max/MaxDepositMintCollateralVaultState.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {MintProtocolRewardsData} from "src/structs/data/vault/common/MintProtocolRewardsData.sol";
import {VaultStateTransition} from "src/state_transition/VaultStateTransition.sol";
import {ApplyMaxGrowthFee} from "src/state_transition/ApplyMaxGrowthFee.sol";
import {MintProtocolRewards} from "src/state_transition/MintProtocolRewards.sol";
import {Lending} from "src/state_transition/Lending.sol";
import {MaxDepositMintCollateralVaultStateReader} from
    "src/state_reader/vault/MaxDepositMintCollateralVaultStateReader.sol";
import {MaxMintCollateral} from "src/public/vault/read/collateral/max/MaxMintCollateral.sol";
import {NextStep} from "src/math/libraries/NextStep.sol";
import {CommonMath} from "src/math/libraries/CommonMath.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

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
                auctionStep: CommonMath.calculateAuctionStep(startAuction, uint56(block.number), auctionDuration)
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
