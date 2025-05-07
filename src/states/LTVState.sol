// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../interfaces/ILendingConnector.sol';
import '../interfaces/IOracleConnector.sol';
import '../interfaces/IWhitelistRegistry.sol';
import '../interfaces/ISlippageProvider.sol';
import '../interfaces/IModules.sol';
import 'forge-std/interfaces/IERC20.sol';
import '../structs/state/vault/TotalAssetsState.sol';
import '../structs/state/MaxGrowthFeeState.sol';
import '../structs/state/vault/PreviewVaultState.sol';
import '../structs/state/vault/MaxDepositMintBorrowVaultState.sol';
import '../structs/state/vault/MaxWithdrawRedeemBorrowVaultState.sol';
import '../structs/state/vault/MaxDepositMintCollateralVaultState.sol';
import '../structs/state/vault/MaxWithdrawRedeemCollateralVaultState.sol';
import '../structs/state/AuctionState.sol';
import '../structs/state/low_level/PreviewLowLevelRebalanceState.sol';
import '../structs/state/low_level/MaxLowLevelRebalanceSharesState.sol';
import '../structs/state/low_level/MaxLowLevelRebalanceBorrowStateData.sol';
import '../structs/state/low_level/MaxLowLevelRebalanceCollateralStateData.sol';
import '../structs/state/low_level/ExecuteLowLevelRebalanceState.sol';

abstract contract LTVState {
    // ------------------------------------------------

    address public feeCollector;

    int256 public futureBorrowAssets;
    int256 public futureCollateralAssets;
    int256 public futureRewardBorrowAssets;
    int256 public futureRewardCollateralAssets;
    uint256 public startAuction;

    // ERC 20 state
    uint256 public baseTotalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name;
    string public symbol;
    uint8 public decimals;

    IERC20 public collateralToken;
    IERC20 public borrowToken;

    uint128 public maxSafeLTV;
    uint128 public minProfitLTV;
    uint128 public targetLTV;

    ILendingConnector public lendingConnector;
    bool public isVaultDeleveraged;
    IOracleConnector public oracleConnector;

    // TODO: why it's internal?
    uint256 internal lastSeenTokenPrice;
    // TODO: why it's internal?
    uint256 internal maxGrowthFee;

    uint256 public maxTotalAssetsInUnderlying;

    mapping(bytes4 => bool) public _isFunctionDisabled;
    ISlippageProvider public slippageProvider;
    bool public isDepositDisabled;
    bool public isWithdrawDisabled;
    IWhitelistRegistry public whitelistRegistry;
    bool public isWhitelistActivated;

    uint256 public maxDeleverageFee;
    ILendingConnector public vaultBalanceAsLendingConnector;

    IModules public modules;

    function getRealCollateralAssets() external view returns (uint256) {
        return lendingConnector.getRealCollateralAssets();
    }

    function getRealBorrowAssets() external view returns (uint256) {
        return lendingConnector.getRealBorrowAssets();
    }

    function getLendingConnector() internal view returns (ILendingConnector) {
        return isVaultDeleveraged ? vaultBalanceAsLendingConnector : lendingConnector;
    }

    function totalAssetsState() internal view returns (TotalAssetsState memory) {
        ILendingConnector _lendingConnector = getLendingConnector();
        return
            TotalAssetsState({
                realCollateralAssets: _lendingConnector.getRealCollateralAssets(),
                realBorrowAssets: _lendingConnector.getRealBorrowAssets(),
                futureBorrowAssets: futureBorrowAssets,
                futureCollateralAssets: futureCollateralAssets,
                futureRewardBorrowAssets: futureRewardBorrowAssets,
                futureRewardCollateralAssets: futureRewardCollateralAssets,
                borrowPrice: oracleConnector.getPriceBorrowOracle(),
                collateralPrice: oracleConnector.getPriceCollateralOracle()
            });
    }

    function maxGrowthFeeState() internal view returns (MaxGrowthFeeState memory) {
        return
            MaxGrowthFeeState({
                totalAssetsState: totalAssetsState(),
                maxGrowthFee: maxGrowthFee,
                supply: baseTotalSupply,
                lastSeenTokenPrice: lastSeenTokenPrice
            });
    }

    function previewVaultState() internal view returns (PreviewVaultState memory) {
        return
            PreviewVaultState({
                maxGrowthFeeState: maxGrowthFeeState(),
                targetLTV: targetLTV,
                startAuction: startAuction,
                blockNumber: block.number,
                collateralSlippage: slippageProvider.collateralSlippage(),
                borrowSlippage: slippageProvider.borrowSlippage()
            });
    }

    function maxDepositMintBorrowVaultState() internal view returns (MaxDepositMintBorrowVaultState memory) {
        return
            MaxDepositMintBorrowVaultState({
                previewVaultState: previewVaultState(),
                minProfitLTV: minProfitLTV,
                maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
            });
    }

    function maxWithdrawRedeemBorrowVaultState(address owner) internal view returns (MaxWithdrawRedeemBorrowVaultState memory) {
        return MaxWithdrawRedeemBorrowVaultState({previewVaultState: previewVaultState(), maxSafeLTV: maxSafeLTV, ownerBalance: balanceOf[owner]});
    }

    function maxDepositMintCollateralVaultState() internal view returns (MaxDepositMintCollateralVaultState memory) {
        return
            MaxDepositMintCollateralVaultState({
                previewVaultState: previewVaultState(),
                minProfitLTV: minProfitLTV,
                maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
            });
    }

    function maxWithdrawRedeemCollateralVaultState(address owner) internal view returns (MaxWithdrawRedeemCollateralVaultState memory) {
        return
            MaxWithdrawRedeemCollateralVaultState({previewVaultState: previewVaultState(), maxSafeLTV: maxSafeLTV, ownerBalance: balanceOf[owner]});
    }

    function getAuctionState() internal view returns (AuctionState memory) {
        return
            AuctionState({
                futureCollateralAssets: futureCollateralAssets,
                futureBorrowAssets: futureBorrowAssets,
                futureRewardBorrowAssets: futureRewardBorrowAssets,
                futureRewardCollateralAssets: futureRewardCollateralAssets,
                startAuction: startAuction
            });
    }

    function previewLowLevelRebalanceState() internal view returns (PreviewLowLevelRebalanceState memory) {
        return PreviewLowLevelRebalanceState({
            maxGrowthFeeState: maxGrowthFeeState(),
            targetLTV: targetLTV,
            blockNumber: block.number,
            startAuction: startAuction
        });
    }

    function executeLowLevelRebalanceState() internal view returns(ExecuteLowLevelRebalanceState memory) {
        return ExecuteLowLevelRebalanceState({
            previewLowLevelRebalanceState: previewLowLevelRebalanceState(),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
        });
    }

    function maxLowLevelRebalanceSharesState() internal view returns (MaxLowLevelRebalanceSharesState memory) {
        return MaxLowLevelRebalanceSharesState({
            maxGrowthFeeState: maxGrowthFeeState(),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
        });
    }

    function maxLowLevelRebalanceBorrowState() internal view returns (MaxLowLevelRebalanceBorrowStateData memory) {
        return MaxLowLevelRebalanceBorrowStateData({
            realBorrowAssets: lendingConnector.getRealBorrowAssets(),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying,
            targetLTV: targetLTV,
            borrowPrice: oracleConnector.getPriceBorrowOracle()
        });
    }

    function maxLowLevelRebalanceCollateralState() internal view returns (MaxLowLevelRebalanceCollateralStateData memory) {
        return MaxLowLevelRebalanceCollateralStateData({
            realCollateralAssets: lendingConnector.getRealCollateralAssets(),
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying,
            targetLTV: targetLTV,
            collateralPrice: oracleConnector.getPriceCollateralOracle()
        });
    }
}
