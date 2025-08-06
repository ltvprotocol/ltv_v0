// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/Constants.sol";
import "src/states/LTVState.sol";
import "src/utils/MulDiv.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "src/state_transition/Lending.sol";
import "src/modifiers/AdministrationModifiers.sol";
import "src/modifiers/FunctionStopperModifier.sol";
import "../state_transition/AdmistrationSetters.sol";
import "../math/MaxGrowthFee.sol";
import "../state_reader/MaxGrowthFeeStateReader.sol";
import "../state_transition/ApplyMaxGrowthFee.sol";

abstract contract AdministrationPublic is
    MaxGrowthFee,
    ApplyMaxGrowthFee,
    MaxGrowthFeeStateReader,
    AdmistrationSetters,
    AdministrationModifiers,
    Lending
{
    using uMulDiv for uint256;
    using sMulDiv for int256;

    function setTargetLTV(uint128 value) external isFunctionAllowed onlyGovernor {
        _setTargetLTV(value);
    }

    function setMaxSafeLTV(uint128 value) external isFunctionAllowed onlyGovernor {
        _setMaxSafeLTV(value);
    }

    function setMinProfitLTV(uint128 value) external isFunctionAllowed onlyGovernor {
        _setMinProfitLTV(value);
    }

    function setFeeCollector(address _feeCollector) external isFunctionAllowed onlyGovernor {
        _setFeeCollector(_feeCollector);
    }

    function setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying)
        external
        isFunctionAllowed
        onlyGovernor
    {
        _setMaxTotalAssetsInUnderlying(_maxTotalAssetsInUnderlying);
    }

    function setMaxDeleverageFeex23(uint24 value) external isFunctionAllowed onlyGovernor {
        _setMaxDeleverageFeex23(value);
    }

    function setIsWhitelistActivated(bool activate) external isFunctionAllowed onlyGovernor {
        _setIsWhitelistActivated(activate);
    }

    function setWhitelistRegistry(IWhitelistRegistry value) external isFunctionAllowed onlyGovernor {
        _setWhitelistRegistry(value);
    }

    function setSlippageProvider(ISlippageProvider _slippageProvider) external isFunctionAllowed onlyGovernor {
        _setSlippageProvider(_slippageProvider);
    }

    function allowDisableFunctions(bytes4[] memory signatures, bool isDisabled) external onlyGuardian {
        _allowDisableFunctions(signatures, isDisabled);
    }

    function setMaxGrowthFeex23(uint256 _maxGrowthFeex23) external isFunctionAllowed onlyGovernor {
        _setMaxGrowthFeex23(_maxGrowthFeex23);
    }

    function setIsDepositDisabled(bool value) external onlyGuardian {
        _setIsDepositDisabled(value);
    }

    function setIsWithdrawDisabled(bool value) external onlyGuardian {
        _setIsWithdrawDisabled(value);
    }

    function setLendingConnector(ILendingConnector _lendingConnector) external onlyOwner {
        _setLendingConnector(_lendingConnector);
    }

    function setOracleConnector(IOracleConnector _oracleConnector) external onlyOwner {
        _setOracleConnector(_oracleConnector);
    }

    function setVaultBalanceAsLendingConnector(address _vaultBalanceAsLendingConnector) external onlyOwner {
        _setVaultBalanceAsLendingConnector(_vaultBalanceAsLendingConnector);
    }

    function deleverageAndWithdraw(uint256 closeAmountBorrow, uint256 deleverageFee)
        external
        onlyEmergencyDeleverager
        nonReentrant
    {
        require(deleverageFee <= maxDeleverageFeex23, ExceedsMaxDeleverageFee(deleverageFee, maxDeleverageFeex23));
        require(!isVaultDeleveraged, VaultAlreadyDeleveraged());
        require(address(vaultBalanceAsLendingConnector) != address(0), VaultBalanceAsLendingConnectorNotSet());

        MaxGrowthFeeState memory state = maxGrowthFeeState();
        MaxGrowthFeeData memory data = maxGrowthFeeStateToData(state);

        applyMaxGrowthFee(_previewSupplyAfterFee(data), data.withdrawTotalAssets);

        futureBorrowAssets = 0;
        futureCollateralAssets = 0;
        futureRewardBorrowAssets = 0;
        futureRewardCollateralAssets = 0;
        startAuction = 0;
        _setMinProfitLTV(0);
        _setTargetLTV(0);
        _setMaxSafeLTV(uint128(Constants.LTV_DIVIDER));

        // round up to repay all assets
        uint256 realBorrowAssets = lendingConnector.getRealBorrowAssets(false, connectorGetterData);

        require(closeAmountBorrow >= realBorrowAssets, ImpossibleToCoverDeleverage(realBorrowAssets, closeAmountBorrow));

        uint256 collateralAssets = lendingConnector.getRealCollateralAssets(false, connectorGetterData);

        uint256 collateralToTransfer = realBorrowAssets.mulDivDown(
            oracleConnector.getPriceBorrowOracle(), oracleConnector.getPriceCollateralOracle()
        );

        collateralToTransfer +=
            (collateralAssets - collateralToTransfer).mulDivDown(deleverageFee, Constants.MAX_GROWTH_FEE_DIVIDER);

        if (realBorrowAssets != 0) {
            borrowToken.transferFrom(msg.sender, address(this), realBorrowAssets);
            repay(realBorrowAssets);
        }

        withdraw(collateralAssets);

        if (collateralToTransfer != 0) {
            collateralToken.transfer(msg.sender, collateralToTransfer);
        }
        isVaultDeleveraged = true;
        connectorGetterData = "";
    }

    function updateEmergencyDeleverager(address newEmergencyDeleverager) external onlyOwner {
        _updateEmergencyDeleverager(newEmergencyDeleverager);
    }

    function updateGovernor(address newGovernor) external onlyOwner {
        _updateGovernor(newGovernor);
    }

    function updateGuardian(address newGuardian) external onlyOwner {
        _updateGuardian(newGuardian);
    }
}
