// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../states/LTVState.sol";
import "../writes/CommonWrite.sol";
import "src/structs/state/StateInitData.sol";
import "src/errors/IInitError.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract InitializeWrite is LTVState, OwnableUpgradeable {
    function initialize(StateInitData memory initData) public initializer {
        __Ownable_init(initData.owner);

        name = initData.name;
        symbol = initData.symbol;
        decimals = initData.decimals;

        collateralToken = IERC20(initData.collateralToken);
        borrowToken = IERC20(initData.borrowToken);

        maxSafeLTV = initData.maxSafeLTV;
        minProfitLTV = initData.minProfitLTV;
        targetLTV = initData.targetLTV;

        lendingConnector = initData.lendingConnector;
        oracleConnector = initData.oracleConnector;
        slippageProvider = initData.slippageProvider;

        feeCollector = initData.feeCollector;
        maxGrowthFee = initData.maxGrowthFee;
        maxDeleverageFee = initData.maxDeleverageFee;

        maxTotalAssetsInUnderlying = initData.maxTotalAssetsInUnderlying;

        vaultBalanceAsLendingConnector = initData.vaultBalanceAsLendingConnector;
        modules = initData.modules;

        governor = initData.governor;
        guardian = initData.guardian;
        emergencyDeleverager = initData.emergencyDeleverager;

        lastSeenTokenPrice = 10 ** 18;

        if (initData.callData.length > 0) {
            (bool success,) = address(this).call(initData.callData);
            require(success, IInitError.FaildedToInitializeWithCallData(initData.callData));
        }
    }
}
