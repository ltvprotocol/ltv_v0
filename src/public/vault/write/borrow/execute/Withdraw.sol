// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC4626Events} from "../../../../../events/IERC4626Events.sol";
import {IVaultErrors} from "../../../../../errors/IVaultErrors.sol";
import {MaxWithdrawRedeemBorrowVaultState} from "../../../../../structs/state/vault/max/MaxWithdrawRedeemBorrowVaultState.sol";
import {MaxWithdrawRedeemBorrowVaultStateReader} from
    "../../../../../state_reader/vault/MaxWithdrawRedeemBorrowVaultStateReader.sol";
import {MaxWithdrawRedeemBorrowVaultData} from "../../../../../structs/data/vault/max/MaxWithdrawRedeemBorrowVaultData.sol";
import {DeltaFuture} from "../../../../../structs/state_transition/DeltaFuture.sol";
import {NextState} from "../../../../../structs/state_transition/NextState.sol";
import {NextStateData} from "../../../../../structs/state_transition/NextStateData.sol";
import {NextStepData} from "../../../../../structs/state_transition/NextStepData.sol";
import {MintProtocolRewardsData} from "../../../../../structs/data/vault/common/MintProtocolRewardsData.sol";
import {VaultStateTransition} from "../../../../../state_transition/VaultStateTransition.sol";
import {ApplyMaxGrowthFee} from "../../../../../state_transition/ApplyMaxGrowthFee.sol";
import {MintProtocolRewards} from "../../../../../state_transition/MintProtocolRewards.sol";
import {Lending} from "../../../../../state_transition/Lending.sol";
import {TransferFromProtocol} from "../../../../../state_transition/TransferFromProtocol.sol";
import {MaxWithdraw} from "../../../read/borrow/max/MaxWithdraw.sol";
import {NextStep} from "../../../../../math/libraries/NextStep.sol";
import {CommonMath} from "../../../../../math/libraries/CommonMath.sol";
import {UMulDiv} from "../../../../../math/libraries/MulDiv.sol";

/**
 * @title Withdraw
 * @notice This contract contains withdraw function implementation.
 */
abstract contract Withdraw is
    MaxWithdrawRedeemBorrowVaultStateReader,
    MaxWithdraw,
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
     * @dev see IBorrowVaultModule.withdraw
     */
    function withdraw(uint256 assets, address receiver, address owner)
        external
        isFunctionAllowed
        nonReentrant
        returns (uint256)
    {
        MaxWithdrawRedeemBorrowVaultState memory state = maxWithdrawRedeemBorrowVaultState(owner);
        MaxWithdrawRedeemBorrowVaultData memory data = maxWithdrawRedeemStateToData(state);
        uint256 max = _maxWithdraw(data);
        require(assets <= max, ExceedsMaxWithdraw(owner, assets, max));

        (uint256 sharesOut, DeltaFuture memory deltaFuture) =
            _previewWithdraw(assets, data.previewWithdrawBorrowVaultData);

        if (sharesOut == 0) {
            return 0;
        }

        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, sharesOut);
        }

        applyMaxGrowthFee(
            data.previewWithdrawBorrowVaultData.supplyAfterFee, data.previewWithdrawBorrowVaultData.withdrawTotalAssets
        );

        _mintProtocolRewards(
            MintProtocolRewardsData({
                deltaProtocolFutureRewardBorrow: deltaFuture.deltaProtocolFutureRewardBorrow,
                deltaProtocolFutureRewardCollateral: deltaFuture.deltaProtocolFutureRewardCollateral,
                supply: data.previewWithdrawBorrowVaultData.supplyAfterFee,
                totalAppropriateAssets: data.previewWithdrawBorrowVaultData.withdrawTotalAssets,
                assetPrice: data.previewWithdrawBorrowVaultData.borrowPrice,
                assetTokenDecimals: data.previewWithdrawBorrowVaultData.borrowTokenDecimals
            })
        );

        _burn(owner, sharesOut);

        NextState memory nextState = NextStep.calculateNextStep(
            NextStepData({
                futureBorrow: data.previewWithdrawBorrowVaultData.futureBorrow,
                futureCollateral: data.previewWithdrawBorrowVaultData.futureCollateral,
                futureRewardBorrow: data.previewWithdrawBorrowVaultData.userFutureRewardBorrow
                    + data.previewWithdrawBorrowVaultData.protocolFutureRewardBorrow,
                futureRewardCollateral: data.previewWithdrawBorrowVaultData.userFutureRewardCollateral
                    + data.previewWithdrawBorrowVaultData.protocolFutureRewardCollateral,
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
                borrowPrice: data.previewWithdrawBorrowVaultData.borrowPrice,
                collateralPrice: state.previewWithdrawVaultState.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
                borrowTokenDecimals: data.previewWithdrawBorrowVaultData.borrowTokenDecimals,
                collateralTokenDecimals: state
                    .previewWithdrawVaultState
                    .maxGrowthFeeState
                    .commonTotalAssetsState
                    .collateralTokenDecimals
            })
        );

        borrow(assets);

        transferBorrowToken(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, sharesOut);

        return sharesOut;
    }
}
