// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWhitelistRegistry} from "src/interfaces/IWhitelistRegistry.sol";
import {ISlippageConnector} from "src/interfaces/connectors/ISlippageConnector.sol";
import {ILendingConnector} from "src/interfaces/connectors/ILendingConnector.sol";
import {IOracleConnector} from "src/interfaces/connectors/IOracleConnector.sol";
import {Constants} from "src/Constants.sol";
import {MaxGrowthFeeState} from "src/structs/state/MaxGrowthFeeState.sol";
import {MaxGrowthFeeData} from "src/structs/data/MaxGrowthFeeData.sol";
import {AdministrationModifiers} from "src/modifiers/AdministrationModifiers.sol";
import {AdmistrationSetters} from "src/state_transition/AdmistrationSetters.sol";
import {ApplyMaxGrowthFee} from "src/state_transition/ApplyMaxGrowthFee.sol";
import {Lending} from "src/state_transition/Lending.sol";
import {MaxGrowthFeeStateReader} from "src/state_reader/MaxGrowthFeeStateReader.sol";
import {MaxGrowthFee} from "src/math/abstracts/MaxGrowthFee.sol";
import {uMulDiv, sMulDiv} from "src/utils/MulDiv.sol";

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
    using SafeERC20 for IERC20;

    function setTargetLtv(uint16 dividend, uint16 divider) external isFunctionAllowed onlyGovernor nonReentrant {
        _setTargetLtv(dividend, divider);
    }

    function setMaxSafeLtv(uint16 dividend, uint16 divider) external isFunctionAllowed onlyGovernor nonReentrant {
        _setMaxSafeLtv(dividend, divider);
    }

    function setMinProfitLtv(uint16 dividend, uint16 divider) external isFunctionAllowed onlyGovernor nonReentrant {
        _setMinProfitLtv(dividend, divider);
    }

    function setFeeCollector(address _feeCollector) external isFunctionAllowed onlyGovernor nonReentrant {
        _setFeeCollector(_feeCollector);
    }

    function setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying)
        external
        isFunctionAllowed
        onlyGovernor
        nonReentrant
    {
        _setMaxTotalAssetsInUnderlying(_maxTotalAssetsInUnderlying);
    }

    function setMaxDeleverageFee(uint16 dividend, uint16 divider)
        external
        isFunctionAllowed
        onlyGovernor
        nonReentrant
    {
        _setMaxDeleverageFee(dividend, divider);
    }

    function setIsWhitelistActivated(bool activate) external isFunctionAllowed onlyGovernor nonReentrant {
        _setIsWhitelistActivated(activate);
    }

    function setWhitelistRegistry(IWhitelistRegistry value) external isFunctionAllowed onlyGovernor nonReentrant {
        _setWhitelistRegistry(value);
    }

    function setSlippageConnector(ISlippageConnector _slippageConnector, bytes memory slippageConnectorData)
        external
        isFunctionAllowed
        onlyGovernor
        nonReentrant
    {
        _setSlippageConnector(_slippageConnector, slippageConnectorData);
    }

    function allowDisableFunctions(bytes4[] memory signatures, bool isDisabled) external onlyGuardian nonReentrant {
        _allowDisableFunctions(signatures, isDisabled);
    }

    function setMaxGrowthFee(uint16 dividend, uint16 divider) external isFunctionAllowed onlyGovernor nonReentrant {
        _setMaxGrowthFee(dividend, divider);
    }

    function setIsDepositDisabled(bool value) external onlyGuardian nonReentrant {
        _setIsDepositDisabled(value);
    }

    function setIsWithdrawDisabled(bool value) external onlyGuardian nonReentrant {
        _setIsWithdrawDisabled(value);
    }

    function setLendingConnector(ILendingConnector _lendingConnector, bytes memory lendingConnectorData)
        external
        onlyOwner
        nonReentrant
    {
        _setLendingConnector(_lendingConnector, lendingConnectorData);
    }

    function setOracleConnector(IOracleConnector _oracleConnector, bytes memory oracleConnectorData)
        external
        onlyOwner
        nonReentrant
    {
        _setOracleConnector(_oracleConnector, oracleConnectorData);
    }

    function setVaultBalanceAsLendingConnector(
        ILendingConnector _vaultBalanceAsLendingConnector,
        bytes memory vaultBalanceAsLendingConnectorGetterData
    ) external onlyOwner nonReentrant {
        _setVaultBalanceAsLendingConnector(_vaultBalanceAsLendingConnector, vaultBalanceAsLendingConnectorGetterData);
    }

    function deleverageAndWithdraw(uint256 closeAmountBorrow, uint16 deleverageFeeDividend, uint16 deleverageFeeDivider)
        external
        onlyEmergencyDeleverager
        nonReentrant
    {
        require(
            deleverageFeeDividend * maxDeleverageFeeDivider <= deleverageFeeDivider * maxDeleverageFeeDividend,
            ExceedsMaxDeleverageFee(
                deleverageFeeDividend, deleverageFeeDivider, maxDeleverageFeeDividend, maxDeleverageFeeDivider
            )
        );
        require(!isVaultDeleveraged(), VaultAlreadyDeleveraged());
        require(address(vaultBalanceAsLendingConnector) != address(0), VaultBalanceAsLendingConnectorNotSet());

        MaxGrowthFeeState memory state = maxGrowthFeeState();
        MaxGrowthFeeData memory data = maxGrowthFeeStateToData(state);

        applyMaxGrowthFee(_previewSupplyAfterFee(data), data.withdrawTotalAssets);

        futureBorrowAssets = 0;
        futureCollateralAssets = 0;
        futureRewardBorrowAssets = 0;
        futureRewardCollateralAssets = 0;
        startAuction = 0;
        _setMinProfitLtv(0, 1);
        _setTargetLtv(0, 1);
        _setMaxSafeLtv(1, 1);

        // round up to repay all assets
        bytes memory _lendingConnectorGetterData = lendingConnectorGetterData;
        uint256 realBorrowAssets = lendingConnector.getRealBorrowAssets(false, _lendingConnectorGetterData);

        require(closeAmountBorrow >= realBorrowAssets, ImpossibleToCoverDeleverage(realBorrowAssets, closeAmountBorrow));

        uint256 collateralAssets = lendingConnector.getRealCollateralAssets(false, _lendingConnectorGetterData);

        bytes memory _oracleConnectorGetterData = oracleConnectorGetterData;

        uint256 collateralToTransfer = realBorrowAssets.mulDivDown(
            oracleConnector.getPriceBorrowOracle(_oracleConnectorGetterData),
            oracleConnector.getPriceCollateralOracle(_oracleConnectorGetterData)
        );

        collateralToTransfer +=
            (collateralAssets - collateralToTransfer).mulDivDown(deleverageFeeDividend, deleverageFeeDivider);

        if (realBorrowAssets != 0) {
            borrowToken.safeTransferFrom(msg.sender, address(this), realBorrowAssets);
            repay(realBorrowAssets);
        }

        withdraw(collateralAssets);

        if (collateralToTransfer != 0) {
            collateralToken.safeTransfer(msg.sender, collateralToTransfer);
        }
        setBool(Constants.IS_VAULT_DELEVERAGED_BIT, true);
        lendingConnectorGetterData = "";
    }

    function updateEmergencyDeleverager(address newEmergencyDeleverager) external onlyOwner nonReentrant {
        _updateEmergencyDeleverager(newEmergencyDeleverager);
    }

    function updateGovernor(address newGovernor) external onlyOwner nonReentrant {
        _updateGovernor(newGovernor);
    }

    function updateGuardian(address newGuardian) external onlyOwner nonReentrant {
        _updateGuardian(newGuardian);
    }
}
