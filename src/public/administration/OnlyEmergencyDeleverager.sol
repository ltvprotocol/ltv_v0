// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "../../Constants.sol";
import {MaxGrowthFeeState} from "../../structs/state/MaxGrowthFeeState.sol";
import {MaxGrowthFeeData} from "../../structs/data/MaxGrowthFeeData.sol";
import {AdministrationModifiers} from "../../modifiers/AdministrationModifiers.sol";
import {AdmistrationSetters} from "../../state_transition/AdmistrationSetters.sol";
import {ApplyMaxGrowthFee} from "../../state_transition/ApplyMaxGrowthFee.sol";
import {Lending} from "../../state_transition/Lending.sol";
import {MaxGrowthFeeStateReader} from "../../state_reader/MaxGrowthFeeStateReader.sol";
import {MaxGrowthFee} from "../../math/abstracts/MaxGrowthFee.sol";
import {uMulDiv, sMulDiv} from "../../utils/MulDiv.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

abstract contract OnlyEmergencyDeleverager is
    AdmistrationSetters,
    MaxGrowthFee,
    ApplyMaxGrowthFee,
    MaxGrowthFeeStateReader,
    AdministrationModifiers,
    Lending
{
    using uMulDiv for uint256;
    using sMulDiv for int256;
    using SafeERC20 for IERC20;

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
}
