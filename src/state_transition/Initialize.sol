// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/structs/state/StateInitData.sol";
import "src/errors/IInitError.sol";
import "./AdmistrationSetters.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract Initialize is AdmistrationSetters, OwnableUpgradeable {
    function initialize(StateInitData memory initData) public onlyInitializing {
        __Ownable_init(initData.owner);

        name = initData.name;
        symbol = initData.symbol;
        decimals = initData.decimals;

        collateralToken = IERC20(initData.collateralToken);
        borrowToken = IERC20(initData.borrowToken);

        _setMaxSafeLTV(initData.maxSafeLTVDividend, initData.maxSafeLTVDivider);
        _setTargetLTV(initData.targetLTVDividend, initData.targetLTVDivider);
        _setMinProfitLTV(initData.minProfitLTVDividend, initData.minProfitLTVDivider);

        _setLendingConnector(initData.lendingConnector);
        _setOracleConnector(initData.oracleConnector);
        _setSlippageProvider(initData.slippageProvider);

        _setFeeCollector(initData.feeCollector);
        _setMaxGrowthFee(initData.maxGrowthFeeDividend, initData.maxGrowthFeeDivider);
        _setMaxDeleverageFee(initData.maxDeleverageFeeDividend, initData.maxDeleverageFeeDivider);

        _setMaxTotalAssetsInUnderlying(initData.maxTotalAssetsInUnderlying);

        vaultBalanceAsLendingConnector = initData.vaultBalanceAsLendingConnector;

        _updateGovernor(initData.governor);
        _updateGuardian(initData.guardian);
        _updateEmergencyDeleverager(initData.emergencyDeleverager);

        lastSeenTokenPrice = 10 ** 18;

        (bool success,) = address(lendingConnector).delegatecall(
            abi.encodeCall(ILendingConnector.initializeProtocol, (initData.lendingConnectorData))
        );
        require(success, IInitError.FaildedToInitialize(initData.lendingConnectorData));

        auctionDuration = initData.auctionDuration;
    }
}
