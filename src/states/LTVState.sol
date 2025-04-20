// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../interfaces/ILendingConnector.sol';
import '../interfaces/IOracleConnector.sol';
import '../interfaces/IWhitelistRegistry.sol';
import '../interfaces/ISlippageProvider.sol';
import '../interfaces/IModules.sol';
import 'forge-std/interfaces/IERC20.sol';
import '../Structs2.sol';

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

    // TODO: why it's internal?
    ILendingConnector internal lendingConnector;
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

    function previewBorrowVaultState() internal view returns (PreviewBorrowVaultState memory) {
        return
            PreviewBorrowVaultState({
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
                previewBorrowVaultState: previewBorrowVaultState(),
                minProfitLTV: minProfitLTV,
                maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
            });
    }

    function maxWithdrawRedeemBorrowVaultState(address owner) internal view returns (MaxWithdrawRedeemBorrowVaultState memory) {
        return
            MaxWithdrawRedeemBorrowVaultState({
                previewBorrowVaultState: previewBorrowVaultState(),
                maxSafeLTV: maxSafeLTV,
                ownerBalance: balanceOf[owner]
            });
    }
}
