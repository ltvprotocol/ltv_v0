// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Constants} from "../../../constants/Constants.sol";
import {MaxGrowthFeeState} from "../../../structs/state/common/MaxGrowthFeeState.sol";
import {MaxGrowthFeeData} from "../../../structs/data/common/MaxGrowthFeeData.sol";
import {AdministrationModifiers} from "../../../modifiers/AdministrationModifiers.sol";
import {AdministrationSetters} from "../../../state_transition/AdministrationSetters.sol";
import {ApplyMaxGrowthFee} from "../../../state_transition/ApplyMaxGrowthFee.sol";
import {Lending} from "../../../state_transition/Lending.sol";
import {MaxGrowthFeeStateReader} from "../../../state_reader/common/MaxGrowthFeeStateReader.sol";
import {MaxGrowthFee} from "../../../math/abstracts/MaxGrowthFee.sol";
import {UMulDiv, SMulDiv} from "../../../math/libraries/MulDiv.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

/**
 * @title OnlyEmergencyDeleverager
 * @notice This contract contains only emergency deleverager public function implementation.
 */
abstract contract OnlyEmergencyDeleverager is
    AdministrationSetters,
    MaxGrowthFee,
    ApplyMaxGrowthFee,
    MaxGrowthFeeStateReader,
    AdministrationModifiers,
    Lending
{
    using UMulDiv for uint256;
    using SMulDiv for int256;
    using SafeERC20 for IERC20;

    /**
     * @dev see ILTV.deleverageAndWithdraw
     */
    function deleverageAndWithdraw(uint256 closeAmountBorrow, uint16 deleverageFeeDividend, uint16 deleverageFeeDivider)
        external
        onlyEmergencyDeleverager
        nonReentrant
    {
        require(
            uint256(deleverageFeeDividend) * maxDeleverageFeeDivider
                <= uint256(deleverageFeeDivider) * maxDeleverageFeeDividend,
            ExceedsMaxDeleverageFee(
                deleverageFeeDividend, deleverageFeeDivider, maxDeleverageFeeDividend, maxDeleverageFeeDivider
            )
        );
        require(!_isVaultDeleveraged(boolSlot), VaultAlreadyDeleveraged());
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
