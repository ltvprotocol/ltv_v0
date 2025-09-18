// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {StateInitData} from "src/structs/state/initialize/StateInitData.sol";
import {AdministrationSetters} from "src/state_transition/AdministrationSetters.sol";
import {Constants} from "src/constants/Constants.sol";

/**
 * @title Initialize
 * @notice contract contains functionality to initialize the vault
 */
abstract contract Initialize is AdministrationSetters, OwnableUpgradeable {
    /**
     * @dev Initializes the vault
     */
    function initialize(StateInitData memory initData) public onlyInitializing {
        __Ownable_init(initData.owner);

        collateralTokenDecimals = IERC20Metadata(initData.collateralToken).decimals();
        borrowTokenDecimals = IERC20Metadata(initData.borrowToken).decimals();

        name = initData.name;
        symbol = initData.symbol;
        decimals = borrowTokenDecimals;

        collateralToken = IERC20(initData.collateralToken);
        borrowToken = IERC20(initData.borrowToken);

        _setMaxSafeLtv(initData.maxSafeLtvDividend, initData.maxSafeLtvDivider);
        _setTargetLtv(initData.targetLtvDividend, initData.targetLtvDivider);
        _setMinProfitLtv(initData.minProfitLtvDividend, initData.minProfitLtvDivider);

        _setFeeCollector(initData.feeCollector);
        _setMaxGrowthFee(initData.maxGrowthFeeDividend, initData.maxGrowthFeeDivider);
        _setMaxDeleverageFee(initData.maxDeleverageFeeDividend, initData.maxDeleverageFeeDivider);

        _setMaxTotalAssetsInUnderlying(initData.maxTotalAssetsInUnderlying);

        _updateGovernor(initData.governor);
        _updateGuardian(initData.guardian);
        _updateEmergencyDeleverager(initData.emergencyDeleverager);

        auctionDuration = initData.auctionDuration;
        lastSeenTokenPrice = Constants.LAST_SEEN_PRICE_PRECISION;

        _setLendingConnector(initData.lendingConnector, initData.lendingConnectorData);
        _setOracleConnector(initData.oracleConnector, initData.oracleConnectorData);
        _setSlippageConnector(initData.slippageConnector, initData.slippageConnectorData);
        _setVaultBalanceAsLendingConnector(
            initData.vaultBalanceAsLendingConnector, initData.vaultBalanceAsLendingConnectorData
        );
    }
}
