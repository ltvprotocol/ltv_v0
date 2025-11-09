// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626Events} from "../../../../../events/IERC4626Events.sol";
import {IVaultErrors} from "../../../../../errors/IVaultErrors.sol";
import {MaxDepositMintCollateralVaultState} from "../../../../../structs/state/vault/max/MaxDepositMintCollateralVaultState.sol";
import {MaxDepositMintCollateralVaultData} from "../../../../../structs/data/vault/max/MaxDepositMintCollateralVaultData.sol";
import {DeltaFuture} from "../../../../../structs/state_transition/DeltaFuture.sol";
import {NextState} from "../../../../../structs/state_transition/NextState.sol";
import {NextStateData} from "../../../../../structs/state_transition/NextStateData.sol";
import {NextStepData} from "../../../../../structs/state_transition/NextStepData.sol";
import {MintProtocolRewardsData} from "../../../../../structs/data/vault/common/MintProtocolRewardsData.sol";
import {VaultStateTransition} from "../../../../../state_transition/VaultStateTransition.sol";
import {ApplyMaxGrowthFee} from "../../../../../state_transition/ApplyMaxGrowthFee.sol";
import {MintProtocolRewards} from "../../../../../state_transition/MintProtocolRewards.sol";
import {Lending} from "../../../../../state_transition/Lending.sol";
import {MaxDepositMintCollateralVaultStateReader} from
    "../../../../../state_reader/vault/MaxDepositMintCollateralVaultStateReader.sol";
import {MaxDepositCollateral} from "../../../read/collateral/max/MaxDepositCollateral.sol";
import {NextStep} from "../../../../../math/libraries/NextStep.sol";
import {CommonMath} from "../../../../../math/libraries/CommonMath.sol";
import {UMulDiv} from "../../../../../math/libraries/MulDiv.sol";

/**
 * @title DepositCollateral
 * @notice This contract contains deposit collateral function implementation.
 */
abstract contract DepositCollateral is
    MaxDepositMintCollateralVaultStateReader,
    MaxDepositCollateral,
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
     * @dev see ILTV.depositCollateral
     */
    function depositCollateral(uint256 assets, address receiver)
        external
        isFunctionAllowed
        nonReentrant
        returns (uint256)
    {
        MaxDepositMintCollateralVaultState memory state = maxDepositMintCollateralVaultState();
        MaxDepositMintCollateralVaultData memory data =
            maxDepositMintCollateralVaultStateToMaxDepositMintCollateralVaultData(state);
        uint256 max = _maxDepositCollateral(data);
        require(assets <= max, ExceedsMaxDepositCollateral(receiver, assets, max));

        (uint256 sharesOut, DeltaFuture memory deltaFuture) =
            _previewDepositCollateral(assets, data.previewCollateralVaultData);

        if (sharesOut == 0) {
            return 0;
        }

        collateralToken.safeTransferFrom(msg.sender, address(this), assets);

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

        emit DepositCollateral(msg.sender, receiver, assets, sharesOut);

        _mintToUser(receiver, sharesOut);

        return sharesOut;
    }
}
