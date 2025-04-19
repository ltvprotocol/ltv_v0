// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../max/MaxMint.sol';
import '../../../../state_transition/VaultStateTransition.sol';
import '../../../../state_transition/ERC20.sol';
import '../../../../state_transition/ApplyMaxGrowthFee.sol';
import '../../../../state_transition/MintProtocolRewards.sol';
import '../../../../state_transition/Lending.sol';
import '../../../../ERC4626Events.sol';
import '../preview/PreviewMint.sol';
import '../../../../math2/NextStep.sol';

abstract contract Mint is MaxMint, ApplyMaxGrowthFee, MintProtocolRewards, Lending, PreviewMint, VaultStateTransition, ERC4626Events {
    using uMulDiv for uint256;

    error ExceedsMaxMint(address receiver, uint256 shares, uint256 max);

    function mint(uint256 shares, address receiver) external isFunctionAllowed nonReentrant returns (uint256 assets) {
        DepositMintData memory data = depositMintStateToData(depositMintState());
        uint256 max = _maxMint(data);
        require(shares <= max, ExceedsMaxMint(receiver, shares, max));

        (uint256 assetsOut, DeltaFuture memory deltaFuture) = _previewMint(shares, data.vaultData);

        if (assetsOut == 0) {
            return 0;
        }

        borrowToken.transferFrom(msg.sender, address(this), assetsOut);

        applyMaxGrowthFee(data.vaultData.supplyAfterFee, data.vaultData.totalAssets);

        _mintProtocolRewards(
            MintProtocolRewardsData({
                deltaProtocolFutureRewardBorrow: deltaFuture.deltaProtocolFutureRewardBorrow,
                deltaProtocolFutureRewardCollateral: deltaFuture.deltaProtocolFutureRewardCollateral,
                supply: data.vaultData.supplyAfterFee,
                totalAssets: data.vaultData.totalAssets,
                borrowPrice: data.vaultData.borrowPrice
            })
        );

        repay(assetsOut);

        NextState memory nextState = NextStep.calculateNextStep(
            NextStepData({
                futureBorrow: data.vaultData.futureBorrow,
                futureCollateral: data.vaultData.futureCollateral,
                futureRewardBorrow: data.vaultData.userFutureRewardBorrow + data.vaultData.protocolFutureRewardBorrow,
                futureRewardCollateral: data.vaultData.userFutureRewardCollateral + data.vaultData.protocolFutureRewardCollateral,
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

        emit Deposit(msg.sender, receiver, assetsOut, shares);

        _mint(receiver, shares);

        return assetsOut;
    }
} 