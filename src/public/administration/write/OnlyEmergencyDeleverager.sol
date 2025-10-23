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
import {TotalAssetsData} from "../../../structs/data/vault/total_assets/TotalAssetsData.sol";
import {TotalAssetsState} from "../../../structs/state/vault/total_assets/TotalAssetsState.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {console} from "forge-std/console.sol";

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
            deleverageFeeDividend * maxDeleverageFeeDivider <= deleverageFeeDivider * maxDeleverageFeeDividend,
            ExceedsMaxDeleverageFee(
                deleverageFeeDividend, deleverageFeeDivider, maxDeleverageFeeDividend, maxDeleverageFeeDivider
            )
        );

        _setMinProfitLtv(0, 1);
        _setTargetLtv(0, 1);
        _setMaxSafeLtv(1, 1);
        _setSoftLiquidationLtv(1, 1);

        _liquidate(closeAmountBorrow, deleverageFeeDividend, deleverageFeeDivider, false);
        setBool(Constants.IS_VAULT_DELEVERAGED_BIT, true);
        lendingConnectorGetterData = "";
    }

    /**
     * @dev see ILTV.softLiquidation
     */
    function softLiquidation(uint256 liquidationAmountBorrow) external onlyEmergencyDeleveragerOrAnyone nonReentrant {
        _liquidate(liquidationAmountBorrow, softLiquidationFeeDividend, softLiquidationFeeDivider, true);
    }

    function _liquidate(
        uint256 liquidationAmountBorrow,
        uint16 bonusDividend,
        uint16 bonusDivider,
        bool isSoftLiquidation
    ) internal {
        require(!_isVaultDeleveraged(boolSlot), VaultAlreadyDeleveraged());

        futureBorrowAssets = 0;
        futureCollateralAssets = 0;
        futureRewardBorrowAssets = 0;
        futureRewardCollateralAssets = 0;
        startAuction = 0;

        MaxGrowthFeeState memory state = maxGrowthFeeState();

        if (!isSoftLiquidation) {
            require(
                liquidationAmountBorrow >= state.withdrawRealBorrowAssets,
                ImpossibleToCoverDeleverage(state.withdrawRealBorrowAssets, liquidationAmountBorrow)
            );
            liquidationAmountBorrow = state.withdrawRealBorrowAssets;
        }

        TotalAssetsData memory totalAssetsData = totalAssetsStateToData(
            TotalAssetsState({
                realCollateralAssets: state.withdrawRealCollateralAssets,
                realBorrowAssets: state.withdrawRealBorrowAssets,
                commonTotalAssetsState: state.commonTotalAssetsState
            }),
            false
        );
        uint256 withdrawTotalAssets = _totalAssets(false, totalAssetsData);

        applyMaxGrowthFee(
            _previewSupplyAfterFee(
                MaxGrowthFeeData({
                    withdrawTotalAssets: withdrawTotalAssets,
                    maxGrowthFeeDividend: state.maxGrowthFeeDividend,
                    maxGrowthFeeDivider: state.maxGrowthFeeDivider,
                    supply: totalSupply(state.supply),
                    lastSeenTokenPrice: state.lastSeenTokenPrice
                })
            ),
            withdrawTotalAssets
        );

        bytes memory _oracleConnectorGetterData = oracleConnectorGetterData;
        uint256 liquidationAmountBorrowInUnderlying = liquidationAmountBorrow.mulDivDown(
            oracleConnector.getPriceBorrowOracle(_oracleConnectorGetterData), 10 ** borrowTokenDecimals
        );
        uint256 liquidationAmountCollateralInUnderlying = liquidationAmountBorrowInUnderlying;

        liquidationAmountCollateralInUnderlying +=
            liquidationAmountCollateralInUnderlying.mulDivDown(bonusDividend, bonusDivider);

        uint256 liquidationAmountCollateral = liquidationAmountCollateralInUnderlying.mulDivDown(
            10 ** collateralTokenDecimals, oracleConnector.getPriceCollateralOracle(_oracleConnectorGetterData)
        );
        if (isSoftLiquidation) {
            require(
                (uint256(totalAssetsData.collateral) - liquidationAmountCollateralInUnderlying)
                    * softLiquidationLtvDivider
                    > (uint256(totalAssetsData.borrow) - liquidationAmountBorrowInUnderlying) * softLiquidationLtvDividend,
                SoftLiquidationResultBelowSoftLiquidationLtv(
                    uint256(totalAssetsData.collateral - liquidationAmountCollateralInUnderlying),
                    uint256(totalAssetsData.borrow - liquidationAmountBorrowInUnderlying),
                    softLiquidationLtvDividend,
                    softLiquidationLtvDivider
                )
            );
        }

        if (liquidationAmountBorrow != 0) {
            borrowToken.safeTransferFrom(msg.sender, address(this), liquidationAmountBorrow);
            repay(liquidationAmountBorrow);
        }

        if (isSoftLiquidation) {
            withdraw(liquidationAmountCollateral);
        } else {
            withdraw(lendingConnector.getRealCollateralAssets(true, lendingConnectorGetterData));
        }
        collateralToken.safeTransfer(msg.sender, liquidationAmountCollateral);
    }
}
