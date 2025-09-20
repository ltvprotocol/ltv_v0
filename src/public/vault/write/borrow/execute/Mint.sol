// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626Events} from "src/events/IERC4626Events.sol";
import {IVaultErrors} from "src/errors/IVaultErrors.sol";
import {MaxDepositMintBorrowVaultState} from "src/structs/state/vault/max/MaxDepositMintBorrowVaultState.sol";
import {MaxDepositMintBorrowVaultStateReader} from "src/state_reader/vault/MaxDepositMintBorrowVaultStateReader.sol";
import {MaxDepositMintBorrowVaultData} from "src/structs/data/vault/max/MaxDepositMintBorrowVaultData.sol";
import {DeltaFuture} from "src/structs/state_transition/DeltaFuture.sol";
import {NextState} from "src/structs/state_transition/NextState.sol";
import {NextStateData} from "src/structs/state_transition/NextStateData.sol";
import {NextStepData} from "src/structs/state_transition/NextStepData.sol";
import {MintProtocolRewardsData} from "src/structs/data/vault/common/MintProtocolRewardsData.sol";
import {VaultStateTransition} from "src/state_transition/VaultStateTransition.sol";
import {ApplyMaxGrowthFee} from "src/state_transition/ApplyMaxGrowthFee.sol";
import {MintProtocolRewards} from "src/state_transition/MintProtocolRewards.sol";
import {Lending} from "src/state_transition/Lending.sol";
import {MaxMint} from "src/public/vault/read/borrow/max/MaxMint.sol";
import {NextStep} from "src/math/libraries/NextStep.sol";
import {CommonMath} from "src/math/libraries/CommonMath.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title Mint
 * @notice This contract contains mint function implementation.
 */
abstract contract Mint is
    MaxDepositMintBorrowVaultStateReader,
    MaxMint,
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
     * @dev see ILTV.mint
     */
    function mint(uint256 shares, address receiver) external isFunctionAllowed nonReentrant returns (uint256 assets) {
        MaxDepositMintBorrowVaultState memory state = maxDepositMintBorrowVaultState();
        MaxDepositMintBorrowVaultData memory data = maxDepositMintStateToData(state);
        uint256 max = _maxMint(data);
        require(shares <= max, ExceedsMaxMint(receiver, shares, max));

        (uint256 assetsOut, DeltaFuture memory deltaFuture) = _previewMint(shares, data.previewDepositBorrowVaultData);

        if (assetsOut == 0) {
            return 0;
        }

        borrowToken.safeTransferFrom(msg.sender, address(this), assetsOut);

        applyMaxGrowthFee(
            data.previewDepositBorrowVaultData.supplyAfterFee, data.previewDepositBorrowVaultData.withdrawTotalAssets
        );

        _mintProtocolRewards(
            MintProtocolRewardsData({
                deltaProtocolFutureRewardBorrow: deltaFuture.deltaProtocolFutureRewardBorrow,
                deltaProtocolFutureRewardCollateral: deltaFuture.deltaProtocolFutureRewardCollateral,
                supply: data.previewDepositBorrowVaultData.supplyAfterFee,
                totalAppropriateAssets: data.previewDepositBorrowVaultData.depositTotalAssets,
                assetPrice: data.previewDepositBorrowVaultData.borrowPrice,
                assetTokenDecimals: data.previewDepositBorrowVaultData.borrowTokenDecimals
            })
        );

        repay(assetsOut);

        NextState memory nextState = NextStep.calculateNextStep(
            NextStepData({
                futureBorrow: data.previewDepositBorrowVaultData.futureBorrow,
                futureCollateral: data.previewDepositBorrowVaultData.futureCollateral,
                futureRewardBorrow: data.previewDepositBorrowVaultData.userFutureRewardBorrow
                    + data.previewDepositBorrowVaultData.protocolFutureRewardBorrow,
                futureRewardCollateral: data.previewDepositBorrowVaultData.userFutureRewardCollateral
                    + data.previewDepositBorrowVaultData.protocolFutureRewardCollateral,
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
                borrowPrice: data.previewDepositBorrowVaultData.borrowPrice,
                collateralPrice: state.previewDepositVaultState.maxGrowthFeeState.commonTotalAssetsState.collateralPrice,
                borrowTokenDecimals: data.previewDepositBorrowVaultData.borrowTokenDecimals,
                collateralTokenDecimals: state
                    .previewDepositVaultState
                    .maxGrowthFeeState
                    .commonTotalAssetsState
                    .collateralTokenDecimals
            })
        );

        emit Deposit(msg.sender, receiver, assetsOut, shares);

        _mintToUser(receiver, shares);

        return assetsOut;
    }
}
